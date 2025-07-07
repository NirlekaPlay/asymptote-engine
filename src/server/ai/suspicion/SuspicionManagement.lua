--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedDetectionRemote)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)
local Statuses = require(ServerScriptService.server.player.Statuses)

local CONFIG = {
	MAX_SUSPICION = 1.0,
	SUSPICION_DECAY_RATE = 0.3,  -- How fast suspicion decreases per update
	SUSPICION_RAISE_RATE = 0.5,  -- Base rate for raising suspicion,
	SUSPICIOUS_THRESHOLD = 0.5
}

local SUSPICION_STATES = {
	CALM = "CALM",
	SUSPICIOUS = "SUSPICIOUS",
	ALERTED = "ALERTED"
}

--[=[
	@class SuspicionManagement
	Manages the raising and lowering of suspicion per player.
]=]
local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement
export type SuspicionManagement = typeof(setmetatable({} :: {
	model: Model,
	suspicionLevels: { [Player]: number },
	currentState: "CALM" | "SUSPICIOUS" | "ALERTED",
	focusingSuspect: Player?
}, SuspicionManagement))

local function getSuspectSuspicionWeight(suspect: Player): number
	local playerStatuses = PlayerStatusReg.getStatus(suspect)
	if not playerStatuses then
		return 0
	else
		local totalWeight = 0
		for status, _ in pairs(playerStatuses) do
			local weight = Statuses.STATUS_BY_WEIGHT[status]
			totalWeight += weight
		end

		return totalWeight
	end
end

function SuspicionManagement.new(model: Model): SuspicionManagement
	return setmetatable({
		model = model,
		suspicionLevels = {},
		currentState = SUSPICION_STATES.CALM,
		focusingSuspect = nil :: Player?
	}, SuspicionManagement)
end

function SuspicionManagement.increaseSuspicion(self: SuspicionManagement, suspect: Player, deltaTime: number): ()
	local suspicionWeight = getSuspectSuspicionWeight(suspect)
	local increase = CONFIG.SUSPICION_RAISE_RATE * suspicionWeight * deltaTime
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0
	self.suspicionLevels[suspect] = math.min(CONFIG.MAX_SUSPICION, currentSuspicion + increase)

	if self.suspicionLevels[suspect] then 
		TypedDetectionRemote:FireClient(suspect, self.suspicionLevels[suspect], self.model, self.model.PrimaryPart.Position)
	end
end

function SuspicionManagement.decreaseSuspicion(self: SuspicionManagement, suspect: Player, deltaTime: number): ()
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0

	if currentSuspicion > 0 then
		local decrease = CONFIG.SUSPICION_DECAY_RATE * deltaTime
		self.suspicionLevels[suspect] = math.max(0.0, currentSuspicion - decrease)

		-- clean up once the level reaches zero
		if self.suspicionLevels[suspect] <= 0 then
			self.suspicionLevels[suspect] = nil
		end
	end

	if self.suspicionLevels[suspect] then
		TypedDetectionRemote:FireClient(suspect, self.suspicionLevels[suspect], self.model, self.model.PrimaryPart.Position)
	end
end

function SuspicionManagement.getMostSuspiciousPlayer(self: SuspicionManagement): (Player?, number)
	local highestPlayer = nil
	local highestValue = -math.huge -- start with the smallest possible number

	for player, suspicion in pairs(self.suspicionLevels) do
		if suspicion > highestValue then
			highestValue = suspicion
			highestPlayer = player
		end
	end

	return highestPlayer, highestValue
end

function SuspicionManagement.update(self: SuspicionManagement, deltaTime: number, visiblePlayers: { Player }): ()
	-- set of visible players for quick lookup
	local visiblePlayersSet = {}
	for _, player in visiblePlayers do
		visiblePlayersSet[player] = true
	end

	local currentState = self.currentState -- for the fucking typechecker to not complain like a bitch
	
	if currentState == SUSPICION_STATES.CALM then
		-- increase suspicion for visible players, decrease for non-visible
		for _, player in visiblePlayers do
			self:increaseSuspicion(player, deltaTime)
		end
		
		-- decrease suspicion for all non visible players
		for player, _ in pairs(self.suspicionLevels) do
			if not visiblePlayersSet[player] then
				self:decreaseSuspicion(player, deltaTime)
			end
		end
		
		-- check if any player reaches suspicious threshold
		local mostSuspicious, highestValue = self:getMostSuspiciousPlayer()
		if mostSuspicious and highestValue >= CONFIG.SUSPICIOUS_THRESHOLD then
			self.currentState = SUSPICION_STATES.SUSPICIOUS
			self.focusingSuspect = mostSuspicious
		end
		
	elseif currentState == SUSPICION_STATES.SUSPICIOUS then
		-- only raise suspicion for the focused suspect if they're visible
		-- (fuck you typechecker)
		if self.focusingSuspect :: Player and visiblePlayersSet[self.focusingSuspect :: Player] then
			self:increaseSuspicion(self.focusingSuspect :: Player, deltaTime)
		end
		
		-- decrease suspicion for all other players (including focused suspect if not visible)
		for player, _ in pairs(self.suspicionLevels) do
			if player ~= self.focusingSuspect or not visiblePlayersSet[player] then
				self:decreaseSuspicion(player, deltaTime)
			end
		end
		
		-- check if focused suspect reaches maximum suspicion
		local suspectValue = self.suspicionLevels[self.focusingSuspect :: Player]
		if suspectValue and suspectValue >= CONFIG.MAX_SUSPICION then
			self.currentState = SUSPICION_STATES.ALERTED
		end

		-- check if focused suspect's suspicion is below the threshold
		if suspectValue and suspectValue < CONFIG.SUSPICIOUS_THRESHOLD then
			self.currentState = SUSPICION_STATES.CALM
			self.focusingSuspect = nil
		end
		
	elseif currentState == SUSPICION_STATES.ALERTED then
		-- only lower suspicion for all players except the focused suspect
		for player, _ in pairs(self.suspicionLevels) do
			if player ~= self.focusingSuspect then
				self:decreaseSuspicion(player, deltaTime)
			end
		end
	end

	--print(self.suspicionLevels)
	--warn(`State: {self.currentState}, Focus: {self.focusingSuspect}`)
end

return SuspicionManagement