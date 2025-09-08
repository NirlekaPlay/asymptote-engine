--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DetectionPayload = require(ReplicatedStorage.shared.network.payloads.DetectionPayload)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local BrainOwner = require(ServerScriptService.server.BrainOwner)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.remotes.TypedRemotes).Detection
local CONFIG = {
	BASE_DETECTION_TIME = 1.25,        -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	QUICK_DETECTION_RANGE = 10,        -- In studs
	QUICK_DETECTION_MULTIPLIER = 3.33, -- If a suspect is within QUICK_DETECTION_RANGE, the detection speed is multiplied by this
	DECAY_RATE_PER_SECOND = 0.2222,    -- Equivalent to 1% per 0.045s
	CURIOUS_THRESHOLD = 60 / 100,      -- 60% progress to trigger curious state
	CURIOUS_COOLDOWN_TIME = 2,         -- In seconds,
	INSTANT_DETECTION_RULES = {
		[PlayerStatusTypes.ARMED] = 20,                    -- Pulling out a gun triggers instant detection within this distance
		[PlayerStatusTypes.DANGEROUS_ITEM] = 12.5          -- Carrying C4 triggers instant detection within this distance
	},
	QUICK_DETECTION_INSTANT_STATUSES = { -- Suspects with this status within the QUICK_DETECTION_RANGE will be instantly detected
		[PlayerStatusTypes.ARMED] = true
	},
	ALERTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp
}

local detectionDataBatch: { [Player]: {DetectionPayload.DetectionData} } = {}
local statusTracker: { [Player]: PlayerStatus.PlayerStatus } = {}

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
	focusingOn: Player?,
	suspicionLevels: { [Player]: { [PlayerStatus.PlayerStatus]: number } },
	detectedStatuses: { [PlayerStatus.PlayerStatus]: Player },
	curiousState: boolean,
	curiousCooldown: number
}, SuspicionManagement))
-- do your thing
function SuspicionManagement.new(agent: DetectionAgent.DetectionAgent & BrainOwner.BrainOwner): SuspicionManagement
	return setmetatable({
		agent = agent,
		focusingOn = nil :: Player?,
		detectedStatuses = {},
		suspicionLevels = {},
		curiousState = false,
		curiousCooldown = 0
	}, SuspicionManagement)
end

function SuspicionManagement.getFocusingTarget(self: SuspicionManagement): Player?
	return self.focusingOn
end

function SuspicionManagement.isCurious(self: SuspicionManagement): boolean
	return self.curiousState
end

function SuspicionManagement.update(self: SuspicionManagement, deltaTime: number): ()
	local hearablePlayers = self.agent:getBrain():getMemory(MemoryModuleTypes.HEARABLE_PLAYERS)
	local visiblePlayers = self.agent:getBrain():getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
	hearablePlayers = hearablePlayers:map(function(hearable)
		return hearable
	end)
		:orElse({})
	visiblePlayers = visiblePlayers:map(function(visible)
		return visible
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

	-- the complexity is necessary for the
	-- actually, i cant explain shit.
	if (focusingTarget and highestStatus) and (not self.detectedStatuses[highestStatus]) then
		self.focusingOn = focusingTarget
		if not self.suspicionLevels[focusingTarget] then
			self.suspicionLevels[focusingTarget] = {}
		end

		local suspicionTable = self.suspicionLevels[focusingTarget]
		local highestPriority = highestStatus:getPriorityLevel()

		-- Step 1: Check for any maxed higher priority status, override highestStatus if found
		for status, level in pairs(suspicionTable) do
			local currentPriority = status:getPriorityLevel()
			if currentPriority > highestPriority and level >= 1.0 then
				highestStatus = status
				highestPriority = currentPriority
				break
			end
		end

		-- Step 2: Build list of currently detected statuses for this player
		local detectedStatuses: { [PlayerStatus.PlayerStatus]: true } = {}
		detectedStatuses[highestStatus] = true

		-- Step 3: For each suspicious status no longer detected, transfer suspicion to detected status of closest priority
		for status, level in pairs(suspicionTable) do
			if not detectedStatuses[status] then
				-- Find detected status with closest priority to 'status'
				local statusPriority = status:getPriorityLevel()
				local candidateStatus: PlayerStatus.PlayerStatus? = nil
				local bestDistance = math.huge  -- Initialize with huge distance

				for detectedStatus, _ in pairs(detectedStatuses) do
					local detectedPriority = detectedStatus:getPriorityLevel()
					local currentDistance = math.abs(detectedPriority - statusPriority)
					if currentDistance < bestDistance then
						candidateStatus = detectedStatus
						bestDistance = currentDistance
					end
				end

				-- Transfer suspicion to candidateStatus if exists and suspicion is not maxed
				if candidateStatus and candidateStatus ~= status then
					if level < 1.0 then
						suspicionTable[candidateStatus] = math.min(1.0, (suspicionTable[candidateStatus] or 0) + level)
					else
						suspicionTable[candidateStatus] = suspicionTable[candidateStatus] or 0
					end
				end

				-- Remove old status if suspicion is not maxed
				if level < 1.0 and (candidateStatus and suspicionTable[candidateStatus] < 1) then
					suspicionTable[status] = nil
				end
			end
		end

		-- Step 3: Transfer suspicion FROM lower priority statuses TO highestStatus before removal
		for status, level in pairs(suspicionTable) do
			if status ~= highestStatus then
				local currentPriority = status:getPriorityLevel()
				if currentPriority < highestPriority and level < 1.0 then
					-- Transfer suspicion to highestStatus before removing
					suspicionTable[highestStatus] = math.max(suspicionTable[highestStatus] or 0, level)
					suspicionTable[status] = nil
				end
			end
		end

		-- Step 5: Ensure highestStatus suspicion level initialized
		if suspicionTable[highestStatus] == nil then
			suspicionTable[highestStatus] = 0
		end

		-- Step 6: Raise suspicion on highestStatus
		self:raiseSuspicion(focusingTarget, highestStatus, deltaTime)
	else
		self.focusingOn = nil
	end

	-- what the fuck.
	if (focusingTarget and highestStatus) and (not self.detectedStatuses[highestStatus]) then
		if self.suspicionLevels[focusingTarget][highestStatus] >= CONFIG.CURIOUS_THRESHOLD then
			self.curiousState = true
			self.curiousCooldown = CONFIG.CURIOUS_COOLDOWN_TIME
		end
	else
		if self.curiousState and self.curiousCooldown > 0 then
			self.curiousCooldown -= deltaTime
		end
	end

	if self.curiousCooldown <= 0 then
		self.curiousState = false
	end

	for player, statusLevels in pairs(self.suspicionLevels) do
		for status, level in pairs(statusLevels) do
			-- Skip lowering suspicion only if this status is the current highest detected status for this player
			if not (player == focusingTarget and status == highestStatus) then
				self:lowerSuspicion(player, status, deltaTime)
			end
		end
	end
end

function SuspicionManagement.raiseSuspicion(
	self: SuspicionManagement,
	player: Player,
	highestStatus: PlayerStatus.PlayerStatus,
	deltaTime: number
): ()
	local playerSus = self.suspicionLevels[player][highestStatus] or 0
	if playerSus >= 1 then return end

	local agentPos = self.agent.character.PrimaryPart.Position
	local playerPos = player.Character.PrimaryPart.Position
	local distance = (agentPos - playerPos).Magnitude

	-- detect status changes
	local previousStatus = statusTracker[player]
	if previousStatus ~= highestStatus then
		statusTracker[player] = highestStatus

		-- check if new status is dangerous and within instant detection range
		local instantRange = CONFIG.INSTANT_DETECTION_RULES[highestStatus] :: number
		if (instantRange and distance <= instantRange)
			or (CONFIG.QUICK_DETECTION_INSTANT_STATUSES[highestStatus] and distance <= CONFIG.QUICK_DETECTION_RANGE) then
			self.suspicionLevels[player][highestStatus] = 1
			self.detectedStatuses[highestStatus] = player
			self:syncSuspicionToPlayer(player, 1)
			return
		end
	end

	-- otherwise, normal suspicion raise
	local speedModifier = highestStatus:getDetectionSpeedModifier()
	if distance <= CONFIG.QUICK_DETECTION_RANGE then
		speedModifier *= CONFIG.QUICK_DETECTION_MULTIPLIER
	end

	local detectionSpeed = 1 + (speedModifier / 100)
	local progressRate = (1 / CONFIG.BASE_DETECTION_TIME) * detectionSpeed

	playerSus = math.clamp(playerSus + progressRate * deltaTime, 0.0, 1.0)
	self.suspicionLevels[player][highestStatus] = playerSus

	if playerSus >= 1 then
		self.detectedStatuses[highestStatus] = player
	end

	self:syncSuspicionToPlayer(player, playerSus)
end

function SuspicionManagement.lowerSuspicion(self: SuspicionManagement, player: Player, highestStatus: PlayerStatus.PlayerStatus, deltaTime: number): ()
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

function SuspicionManagement.getHighestPriorityPlayer(self: SuspicionManagement, players: { [Player]: { isVisible: boolean, isHeard: boolean } }): (Player?, PlayerStatus.PlayerStatus?)
	local character = self.agent.character
	local characterPos = character.PrimaryPart.Position

	local bestPlayer = nil
	local bestPlayerStatus = nil
	local bestPriority = -math.huge -- higher number equals higher priority
	local closestDistance = math.huge

	for player, profile in pairs(players) do
		local statuses = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not statuses then continue end
		local priorityStatus = statuses:getHighestDetectableStatus(profile.isVisible or false, profile.isHeard or false)
		--warn(`Player: '{player}' with highest detectable status of '{priorityStatus}'`)

		if not priorityStatus then
			continue
		end

		-- TODO: this is dumb. should be a seperate logic.
		-- but theres no other way i can implement this without causing an aneurysm.
		if priorityStatus == PlayerStatusTypes.DISGUISED and not self.agent:canDetectThroughDisguises() then
			continue
		end

		local priorityValue = priorityStatus:getPriorityLevel()

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
	if susValue >= 1 then
		local sound = CONFIG.ALERTED_SOUND:Clone()
		sound.Parent = character.PrimaryPart :: BasePart
		sound.PlayOnRemove = true
		sound:Destroy()
	end

	SuspicionManagement.addToBatch(player, {
		character = character,
		uuid = self.agent:getUuid() :: string,
		detectionValue = susValue
	})
end

--

function SuspicionManagement.addToBatch(to: Player, data: DetectionPayload.DetectionData)
	if not detectionDataBatch[to] then
		detectionDataBatch[to] = {}
	end

	table.insert(detectionDataBatch[to], data)
end

function SuspicionManagement.flushBatchToClients(): ()
	for player, datas in pairs(detectionDataBatch) do
		TypedDetectionRemote:FireClient(player, datas)
	end

	table.clear(detectionDataBatch)
end

return SuspicionManagement