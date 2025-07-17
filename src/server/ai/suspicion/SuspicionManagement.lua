--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedDetectionRemote)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)
local Statuses = require(ServerScriptService.server.player.Statuses)

local CONFIG = {
	BASE_DETECTION_TIME = 2.5,      -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	DECAY_RATE_PER_SECOND = 0.2222, -- Equivalent to 1% per 0.045s
	FOCUS_DISTANCE_THRESHOLD = 50,  -- Maximum distance to consider for focusing
}

local STATUSES_BY_PRIORITY = {
	DISGUISED = 1,
	MINOR_TRESPASSING = 2,
	MINOR_SUSPICIOUS = 3,
	MAJOR_TRESPASSING = 4,
	CRIMINAL_SUSPICIOUS = 5,
	ARMED = 6
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
	excludedSuspect: {
		suspect: Player,
		forStatus: Statuses.PlayerStatus
	}?,
	focusingOn: Player?,
	curiousTimer: number,
	amICurious: boolean
}, SuspicionManagement))

function SuspicionManagement.new(model: Model): SuspicionManagement
	return setmetatable({
		model = model,
		suspicionLevels = {},
		focusingOn = nil :: Player?,
		amICurious = false,
		curiousTimer = 2,
		excludedSuspect = nil :: any -- stfu
	}, SuspicionManagement)
end

function SuspicionManagement.getDistanceToPlayer(self: SuspicionManagement, player: Player): number?
	local character = self.model
	local playerCharacter = player.Character
	
	if not character or not character.PrimaryPart then
		return nil
	end
	
	if not playerCharacter or not playerCharacter.PrimaryPart then
		return nil
	end
	
	return (character.PrimaryPart.Position - playerCharacter.PrimaryPart.Position).Magnitude
end

function SuspicionManagement.calculatePlayerPriority(
	self: SuspicionManagement, 
	player: Player
): number
	local distance = self:getDistanceToPlayer(player)
	if not distance then
		return 0
	end
	
	-- Get highest priority status
	local highestStatus = self:getHighestPriorityStatusOfPlayer(player)
	local statusPriority = highestStatus and STATUSES_BY_PRIORITY[highestStatus] or 0
	
	-- Calculate priority score (higher = more priority)
	-- Closer distance and higher status = higher priority
	local distanceScore = math.max(0, CONFIG.FOCUS_DISTANCE_THRESHOLD - distance)
	local priority = (statusPriority * 10) + distanceScore
	
	return priority
end

function SuspicionManagement.updateFocusTarget(
	self: SuspicionManagement,
	visiblePlayers: { [Player]: true }
): ()
	local highestPriority = 0
	local targetPlayer: Player? = nil
	
	-- Find the player with highest priority (closest + highest status)
	for player in pairs(visiblePlayers) do
		local playerSusLevel = PlayerStatusReg.getSuspiciousLevel(player)
		if not playerSusLevel:isSuspicious() then
			continue
		end

		local priority = self:calculatePlayerPriority(player)
		if priority > highestPriority then
			highestPriority = priority
			targetPlayer = player
		end
	end
	
	-- Update focusing target
	self.focusingOn = targetPlayer
end

function SuspicionManagement.update(
	self: SuspicionManagement,
	deltaTime: number,
	visiblePlayers: { [Player]: true }
): ()
	-- Update focus target based on priority
	self:updateFocusTarget(visiblePlayers)
	
	-- Raise suspicion for visible suspicious players
	for player in pairs(visiblePlayers) do
		local playerSusLevel = PlayerStatusReg.getSuspiciousLevel(player)
		if not playerSusLevel:isSuspicious() then
			continue
		end
		
		local playerSus = self.suspicionLevels[player] or 0
		if playerSus >= 1 then
			continue
		end
		
		local weight = playerSusLevel:getTotalWeight() or 0
		local detectionSpeed = 1 + (weight / 100)
		
		local progressRate = (1 / CONFIG.BASE_DETECTION_TIME) * detectionSpeed
		playerSus = math.clamp(playerSus + progressRate * deltaTime, 0.0, 1.0)
		
		self.suspicionLevels[player] = playerSus
		self:syncSuspicionToPlayer(player, playerSus)
	end

	if self.focusingOn and self.suspicionLevels[self.focusingOn] >= 1 then
		self.excludedSuspect = {
			suspect = self.focusingOn,
			forStatus = self:getHighestPriorityStatusOfPlayer(self.focusingOn)
		}
		self.amICurious = false
	end
	
	-- Decay suspicion for players not visible or not suspicious
	for player, level in pairs(self.suspicionLevels) do
		local susLevel = PlayerStatusReg.getSuspiciousLevel(player)
		local isSus = susLevel:isSuspicious()

		if self.excludedSuspect and player == self.excludedSuspect.suspect then
			if not isSus then
				self.excludedSuspect = nil
				self.suspicionLevels[player] = nil
				self.focusingOn = nil
				self.amICurious = false
			end
			continue
		end

		if not (visiblePlayers[player] and isSus) then
			local finalSus = math.max(0, level - CONFIG.DECAY_RATE_PER_SECOND * deltaTime)
			if finalSus > 0 then
				self.suspicionLevels[player] = finalSus
				self:syncSuspicionToPlayer(player, finalSus)
			else
				self.suspicionLevels[player] = nil
			end
		end
	end

	if self.focusingOn then
		if math.map(self.suspicionLevels[self.focusingOn], 0, 1, 0, 100) >= 60 then
			self.amICurious = true
			self.curiousTimer = 2
		else
			self.curiousTimer -= deltaTime
		end
	else
		self.curiousTimer -= deltaTime
	end

	if self.curiousTimer <= 0 then
		self.amICurious = false
	end
end

function SuspicionManagement.getHighestPriorityStatusOfPlayer(self: SuspicionManagement, player: Player): Statuses.PlayerStatus?
	local playerStatuses = PlayerStatusReg.getSuspiciousLevel(player):getStatuses()
	local highestStatus = next(playerStatuses)
	
	if highestStatus == nil then
		return nil
	end
	
	for status in pairs(playerStatuses) do
		if STATUSES_BY_PRIORITY[status] > STATUSES_BY_PRIORITY[highestStatus] then
			highestStatus = status
		end
	end
	
	return highestStatus
end

function SuspicionManagement.syncSuspicionToPlayer(
	self: SuspicionManagement,
	player: Player,
	susValue: number
): ()
	local character = self.model
	local fromPos = character.PrimaryPart.Position
	TypedDetectionRemote:FireClient(
		player,
		susValue,
		character,
		fromPos
	)
end

-- Helper function to get current focus target
function SuspicionManagement.getFocusTarget(self: SuspicionManagement): Player?
	return self.focusingOn
end

return SuspicionManagement