--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStatus = require("../../player/PlayerStatus")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedDetectionRemote)

local CONFIG = {
	BASE_DETECTION_TIME = 1.25,        -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	QUICK_DETECTION_RANGE = 10,        -- In studs
	QUICK_DETECTION_MULTIPLIER = 3.33, -- 
	DECAY_RATE_PER_SECOND = 0.2222,    -- Equivalent to 1% per 0.045s
	CURIOUS_THRESHOLD = 60 / 100,      -- 60% progress to trigger curious state
	CURIOUS_COOLDOWN_TIME = 2          -- In seconds
}

--[=[
	@class SuspicionManagement

	Manages the raising and lowering of suspicion per player.
	The manager always chooses the Player that has the highest
	priority status and is closest to the Agent. Player's
	statuses also affects the speed of their detection.

	The manager will enter a Curious state whenever a Player's
	detection progress reaches 60% or more. It will exit Curious
	state when it is not detecting anything for 2 seconds.
]=]
local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement

export type SuspicionManagement = typeof(setmetatable({} :: {
	character: Model,
	focusingOn: Player?,
	detectionLocks: { [Player]: PlayerStatus.PlayerStatusType },
	suspicionLevels: { [Player]: number },
	curious: boolean,
	curiousCooldown: number
}, SuspicionManagement))

function SuspicionManagement.new(character: Model): SuspicionManagement
	return setmetatable({
		character = character,
		detectionLocks = {},
		suspicionLevels = {},
		focusingOn = nil :: Player?,
		curious = false,
		curiousCooldown = CONFIG.CURIOUS_COOLDOWN_TIME
	}, SuspicionManagement)
end

function SuspicionManagement.getFocusingTarget(self: SuspicionManagement): Player?
	return self.focusingOn
end

function SuspicionManagement.isCurious(self: SuspicionManagement): boolean
	return self.curious
end

function SuspicionManagement.update(self: SuspicionManagement, deltaTime: number, detectedPlayers: { [Player]: true }): ()
	self.focusingOn = self:getHighestPriorityPlayer(detectedPlayers)

	if self.focusingOn then
		self:raiseSuspicion(self.focusingOn, deltaTime)
		if self.suspicionLevels[self.focusingOn] >= CONFIG.CURIOUS_THRESHOLD then
			self.curious = true
			self.curiousCooldown = CONFIG.CURIOUS_COOLDOWN_TIME
		end
	else
		if self.curious and self.curiousCooldown > 0 then
			self.curiousCooldown -= deltaTime
		end
	end

	if self.curiousCooldown <= 0 then
		self.curious = false
	end

	for player in pairs(self.suspicionLevels) do
		if player == self.focusingOn then
			continue
		end

		self:lowerSuspicion(player, deltaTime)
	end
end

function SuspicionManagement.getHighestPriorityPlayer(self: SuspicionManagement, players: { [Player]: true }): Player?
	local character = self.character
	local characterPos = character.PrimaryPart.Position

	local bestPlayer = nil
	local bestPriority = -math.huge -- Assume higher number = higher priority
	local closestDistance = math.huge

	for player in pairs(players) do
		local statuses = PlayerStatusRegistry.getPlayerStatuses(player)
		local priorityStatus = statuses:getHighestPriorityStatus()

		if not priorityStatus then
			continue
		end

		local priorityValue = PlayerStatus.getStatusPriorityValue(priorityStatus)

		local targetCharacter = player.Character
		if targetCharacter and targetCharacter.PrimaryPart then
			local distance = (targetCharacter.PrimaryPart.Position - characterPos).Magnitude

			-- Check for highest priority, and in case of tie, choose closest
			local isBetterPriority = priorityValue > bestPriority
			local isSamePriorityButCloser = priorityValue == bestPriority and distance < closestDistance

			if isBetterPriority or isSamePriorityButCloser then
				bestPlayer = player
				bestPriority = priorityValue
				closestDistance = distance
			end
		end
	end

	return bestPlayer
end

function SuspicionManagement.raiseSuspicion(self: SuspicionManagement, player: Player, deltaTime: number): ()
	local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
	local playerSus = self.suspicionLevels[player] or 0

	local highestStatus = playerStatus:getHighestPriorityStatus() :: PlayerStatus.PlayerStatusType
	local statusPriority = PlayerStatus.getStatusPriorityValue(highestStatus)
	local lockedStatus = self.detectionLocks[player]
	if playerSus >= 1 then
		-- Already fully detected
		if lockedStatus then
			local lockedPriority = PlayerStatus.getStatusPriorityValue(lockedStatus)
			if statusPriority <= lockedPriority then
				-- Ignore further suspicion because no escalation
				return
			end
		end
	end

	local highestPriorityStatus = playerStatus:getHighestPriorityStatus() :: PlayerStatus.PlayerStatusType
	local speedModifier = PlayerStatus.getStatusDetectionSpeedModifier(highestPriorityStatus)
	local distance = (self.character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
	if distance <= CONFIG.QUICK_DETECTION_RANGE then
		speedModifier *= CONFIG.QUICK_DETECTION_MULTIPLIER
	end
	local detectionSpeed = 1 + (speedModifier / 100)

	local progressRate = (1 / CONFIG.BASE_DETECTION_TIME) * detectionSpeed
	playerSus = math.clamp(playerSus + progressRate * deltaTime, 0.0, 1.0)

	if playerSus >= 1 then
		self.detectionLocks[player] = highestStatus
	end
	
	self.suspicionLevels[player] = playerSus
	self:syncSuspicionToPlayer(player, playerSus)
end

function SuspicionManagement.lowerSuspicion(self: SuspicionManagement, player: Player, deltaTime: number): ()
	local level = self.suspicionLevels[player] or 0
	if level >= 1 then return end

	local finalSus = math.max(0, level - CONFIG.DECAY_RATE_PER_SECOND * deltaTime)
	if finalSus > 0 then
		self.suspicionLevels[player] = finalSus
		self:syncSuspicionToPlayer(player, finalSus)
	else
		self.suspicionLevels[player] = nil
	end
end

function SuspicionManagement.decaySuspicionOnAllPlayers(self: SuspicionManagement, deltaTime: number): ()
	for player, level in pairs(self.suspicionLevels) do
		if not (level >= 1) then
			self:lowerSuspicion(player, deltaTime)
		end
	end
end

function SuspicionManagement.syncSuspicionToPlayer(
	self: SuspicionManagement,
	player: Player,
	susValue: number
): ()
	local character = self.character
	local fromPos = character.PrimaryPart.Position
	TypedDetectionRemote:FireClient(
		player,
		susValue,
		character,
		fromPos
	)
end

return SuspicionManagement