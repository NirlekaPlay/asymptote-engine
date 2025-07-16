--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedDetectionRemote)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)
local Statuses = require(ServerScriptService.server.player.Statuses)

local CONFIG = {
	BASE_DETECTION_TIME = 2.5,     -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	DECAY_RATE_PER_SECOND = 0.2222 -- Equivalent to 1% per 0.045s
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
	focusingOn: Player?
}, SuspicionManagement))

function SuspicionManagement.new(model: Model): SuspicionManagement
	return setmetatable({
		model = model,
		suspicionLevels = {},
		focusingOn = nil :: Player?
	}, SuspicionManagement)
end

function SuspicionManagement.update(
	self: SuspicionManagement,
	deltaTime: number,
	visiblePlayers: { [Player]: true }
): ()

	for player in pairs(visiblePlayers) do
		local playerSusLevel = PlayerStatusReg.getSuspiciousLevel(player)
		if not playerSusLevel:isSuspicious() then
			continue
		end

		local playerSus = self.suspicionLevels[player] or 0
		if playerSus >= 1 then
			continue
		end
		local weight = playerSusLevel:getWeight() or 0
		local detectionSpeed = 1 + (weight / 100)
		local progressRate = (1 / CONFIG.BASE_DETECTION_TIME) * detectionSpeed
		playerSus = math.clamp(playerSus + progressRate * deltaTime, 0.0, 1.0)

		self.suspicionLevels[player] = playerSus

		self:syncSuspicionToPlayer(player, playerSus)
	end

	for player, level in pairs(self.suspicionLevels) do
		local susLevel = PlayerStatusReg.getSuspiciousLevel(player)
		if not (visiblePlayers[player] and susLevel:isSuspicious()) then
			local finalSus = math.max(0, level - CONFIG.DECAY_RATE_PER_SECOND * deltaTime)
			if finalSus > 0 then
				self.suspicionLevels[player] = finalSus
				self:syncSuspicionToPlayer(player, finalSus)
			else
				self.suspicionLevels[player] = nil
			end
		end
	end
end

function SuspicionManagement.getHighestPriorityStatusOfPlayer(player: Player): Statuses.PlayerStatus?
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

return SuspicionManagement