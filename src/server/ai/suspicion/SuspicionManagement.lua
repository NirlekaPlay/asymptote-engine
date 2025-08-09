--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainOwner = require(ServerScriptService.server.BrainOwner)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local PlayerStatus = require("../../player/PlayerStatus")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedRemotes).Detection

local CONFIG = {
	BASE_DETECTION_TIME = 1.25,        -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	QUICK_DETECTION_RANGE = 10,        -- In studs
	QUICK_DETECTION_MULTIPLIER = 3.33, -- 
	DECAY_RATE_PER_SECOND = 0.2222,    -- Equivalent to 1% per 0.045s
	CURIOUS_THRESHOLD = 60 / 100,      -- 60% progress to trigger curious state
	CURIOUS_COOLDOWN_TIME = 2,         -- In seconds,
	ALERTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp
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
	agent: DetectionAgent.DetectionAgent & BrainOwner.BrainOwner,
	suspicionLevels: { [Player]: { [PlayerStatus.PlayerStatusType]: number } }
}, SuspicionManagement))

function SuspicionManagement.new(agent: DetectionAgent.DetectionAgent & BrainOwner.BrainOwner): SuspicionManagement
	return setmetatable({
		agent = agent,
		detectionLocks = {},
		suspicionLevels = {},
	}, SuspicionManagement)
end

function SuspicionManagement.getFocusingTarget(self: SuspicionManagement): Player?
	return nil
end

function SuspicionManagement.isCurious(self: SuspicionManagement): boolean
	return false
end

function SuspicionManagement.update(self: SuspicionManagement, deltaTime: number): ()
	local hearablePlayers = self.agent:getBrain():getMemory(MemoryModuleTypes.HEARABLE_PLAYERS)
	local visiblePlayers = self.agent:getBrain():getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
	hearablePlayers = hearablePlayers
		:map(function(expValue)
			return expValue:getValue()
		end)
		:orElse({})
	visiblePlayers = visiblePlayers
		:map(function(expValue)
			return expValue:getValue()
		end)
		:orElse({})

	local totalDetectedPlayers: { [Player]: { isVisible: boolean, isHeard: boolean } } = {}

	for player in pairs(hearablePlayers) do
		if not totalDetectedPlayers[player] then
			totalDetectedPlayers[player] = {}
		end
		totalDetectedPlayers[player]["isHeard"] = true
	end

	for player in pairs(visiblePlayers) do
		if not totalDetectedPlayers[player] then
			totalDetectedPlayers[player] = {}
		end
		totalDetectedPlayers[player]["isVisible"] = true
	end

	local focusingTarget, highestStatus = self:getHighestPriorityPlayer(totalDetectedPlayers)

	if focusingTarget and highestStatus then
		if not self.suspicionLevels[focusingTarget] then
			self.suspicionLevels[focusingTarget] = {}
		end

		for status, number in pairs(self.suspicionLevels[focusingTarget]) do
			local currentPriority = PlayerStatus.getStatusPriorityValue(status)
			local newPriority = PlayerStatus.getStatusPriorityValue(highestStatus)

			-- If the old status no longer applies but another one exists, transfer suspicion
			if status ~= highestStatus and not totalDetectedPlayers[focusingTarget][status] then
				-- Transfer suspicion progress to the new active status
				self.suspicionLevels[focusingTarget][highestStatus] = math.max(
					self.suspicionLevels[focusingTarget][highestStatus] or 0,
					number
				)
				self.suspicionLevels[focusingTarget][status] = nil
			end

			-- Prevent downgrading from a maxed high-priority status
			if currentPriority > newPriority and number >= 1.0 then
				highestStatus = status
				break
			end

			-- Upgrade logic
			if currentPriority < newPriority then
				-- If the old status was maxed, start the new one at 0 and keep the old one
				if number >= 1.0 then
					self.suspicionLevels[focusingTarget][highestStatus] = 0
					-- Keep old status — do NOT remove it
				else
					self.suspicionLevels[focusingTarget][highestStatus] = number
					self.suspicionLevels[focusingTarget][status] = nil
				end
			end
		end

		-- what the fuck?
		self:raiseSuspicion(focusingTarget, highestStatus, deltaTime)
	end

	-- i think im forgetting some shit here
	for player, statusLevels in pairs(self.suspicionLevels) do
		if player == focusingTarget then
			continue
		end

		for status, level in pairs(statusLevels) do
			self:lowerSuspicion(player, status, deltaTime)
		end
	end

	print(self.suspicionLevels)
end

function SuspicionManagement.raiseSuspicion(self: SuspicionManagement, player: Player, highestStatus: PlayerStatus.PlayerStatusType, deltaTime: number): ()
	local playerSus = self.suspicionLevels[player][highestStatus] or 0
	if playerSus >= 1 then
		return
	end
	local speedModifier = PlayerStatus.getStatusDetectionSpeedModifier(highestStatus)
	local distance = (self.agent.character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
	if distance <= CONFIG.QUICK_DETECTION_RANGE then
		speedModifier *= CONFIG.QUICK_DETECTION_MULTIPLIER
	end
	local detectionSpeed = 1 + (speedModifier / 100)

	local progressRate = (1 / CONFIG.BASE_DETECTION_TIME) * detectionSpeed
	playerSus = math.clamp(playerSus + progressRate * deltaTime, 0.0, 1.0)

	self.suspicionLevels[player][highestStatus] = playerSus
	self:syncSuspicionToPlayer(player, playerSus)
end

function SuspicionManagement.lowerSuspicion(self: SuspicionManagement, player: Player, highestStatus: PlayerStatus.PlayerStatusType, deltaTime: number): ()
	local level = self.suspicionLevels[player][highestStatus] or 0
	if level >= 1 then return end

	local finalSus = math.max(0, level - CONFIG.DECAY_RATE_PER_SECOND * deltaTime)
	if finalSus > 0 then
		self.suspicionLevels[player][highestStatus] = finalSus
	else
		self.suspicionLevels[player][highestStatus] = nil
	end
	self:syncSuspicionToPlayer(player, finalSus)
end

function SuspicionManagement.getHighestPriorityPlayer(self: SuspicionManagement, players: { [Player]: { isVisible: boolean, isHeard: boolean } }): (Player?, PlayerStatus.PlayerStatusType?)
	local character = self.agent.character
	local characterPos = character.PrimaryPart.Position

	local bestPlayer = nil
	local bestPlayerStatus = nil
	local bestPriority = -math.huge -- Assume higher number = higher priority
	local closestDistance = math.huge

	for player, profile in pairs(players) do
		local statuses = PlayerStatusRegistry.getPlayerStatuses(player)
		local priorityStatus = statuses:getHighestDetectableStatus(profile.isVisible or false, profile.isHeard or false)
		--warn(`Player: '{player}' with highest detectable status of '{priorityStatus}'`)

		if not priorityStatus then
			continue
		end

		if priorityStatus == "DISGUISED" and not self.agent:canDetectThroughDisguises() then
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
				bestPlayerStatus = priorityStatus
				bestPriority = priorityValue
				closestDistance = distance
			end
		end
	end

	return bestPlayer, bestPlayerStatus
end

function SuspicionManagement.syncSuspicionToPlayer(
	self: SuspicionManagement,
	player: Player,
	susValue: number
): ()
	local character = self.agent.character
	local fromPos = character.PrimaryPart.Position
	if susValue >= 1 then
		local sound = CONFIG.ALERTED_SOUND:Clone()
		sound.Parent = character.PrimaryPart
		sound.PlayOnRemove = true
		sound:Destroy()
	end
	TypedDetectionRemote:FireClient(
		player,
		susValue,
		character,
		fromPos
	)
end

return SuspicionManagement