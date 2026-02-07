--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectableEntity = require(ServerScriptService.server.ai.detection.entity.DetectableEntity)
local DetectionAgent = require(ServerScriptService.server.ai.detection.DetectionAgent)
local DetectionTracker = require(ServerScriptService.server.ai.detection.DetectionTracker)

local DECAY_RATE_PER_SEC = 0.01 / 0.045 -- ≈ 0.222 (Sec. 1(d) of Plan doc.)

--[=[
	@class DetectionManager

	Handles what an entity can detect.
]=]
local DetectionManager = {}
DetectionManager.__index = DetectionManager

export type DetectionManager = typeof(setmetatable({} :: {
	agent: DetectionAgent.DetectionAgent,
	trackers: { [DetectableEntity.DetectableEntity]: DetectionTracker.DetectionTracker },
	highestTarget: DetectableEntity.DetectableEntity?
}, DetectionManager))

function DetectionManager.new(agent: DetectionAgent.DetectionAgent): DetectionManager
	return setmetatable({
		agent = agent,
		trackers = {},
		highestTarget = nil :: DetectableEntity.DetectableEntity?
	}, DetectionManager)
end

function DetectionManager.processPerception(self: DetectionManager, perceived: {DetectableEntity.DetectableEntity}, deltaTime: number): ()
	local seenThisFrame: { [DetectableEntity.DetectableEntity]: boolean } = {}
	
	-- 1. Identify the "Priority Floor"
	-- "If an Agent fully detects an entity, any lower priority entities are ignored."
	local priorityFloor = 0
	for entity, tracker in self.trackers do
		if tracker.value >= 1 then
			priorityFloor = math.max(priorityFloor, entity:getPriority())
		end
	end

	for _, entity in perceived do
		local priority = entity:getPriority()
		
		-- Lead's Rule: Ignore lower priority than what's already fully detected
		if priority < priorityFloor then
			continue
		end

		-- Note: If priority >= priorityFloor, we process it. 
		-- This satisfies: "if another... has a status of higher priority, it will detect on that too."
		
		local tracker = self:getOrCreateTracker(entity)
		
		-- Logic Transfer: The tracker is tied to the Entity instance. 
		-- If the entity changes status (e.g. from 'Suspicious' to 'Armed'), 
		-- it simply returns a higher value from calculateSpeed(). 
		-- The 'value' (0-1) persists, effectively "transferring" the detection progress.
		
		local distance = (self.agent:getPosition() - entity:getPosition()).Magnitude
		local speed = self:calculateSpeed(entity, distance)
		
		tracker:increase(speed * deltaTime)
		seenThisFrame[entity] = true
	end

	-- 2. Decay logic for entities no longer seen
	for entity, tracker in self.trackers do
		if not seenThisFrame[entity] then
			tracker:decay(DECAY_RATE_PER_SEC, deltaTime)
			if tracker.value <= 0 then 
				self.trackers[entity] = nil 
			end
		end
	end

	self:updateHighestPriority()
end

function DetectionManager.updateHighestPriority(self: DetectionManager): ()
	local bestTarget: DetectableEntity.DetectableEntity? = nil
	local highestScore = -1
	local activeFloor = -1

	-- Step 1: Find the floor based on what is ALREADY at 1.0 value
	for entity, tracker in self.trackers do
		if tracker.value >= 1.0 then
			activeFloor = math.max(activeFloor, entity:getBasePriority())
		end
	end

	-- Step 2: Only consider entities that meet or beat that floor
	for entity, tracker in self.trackers do
		local priority = entity:getBasePriority()
		
		if priority < activeFloor then
			continue
		end

		-- Tie-breaking: If priorities are same, focus on the one closest to being fully detected
		local score = priority + tracker.value 
		
		if score > highestScore then
			highestScore = score
			bestTarget = entity
		end
	end

	self.highestTarget = bestTarget
end

function DetectionManager.getOrCreateTracker(self: DetectionManager, entity: DetectableEntity.DetectableEntity): DetectionTracker.DetectionTracker
	local tracker = self.trackers[entity]

	if not tracker then
		tracker = DetectionTracker.new(entity)
		self.trackers[entity] = tracker
	end

	return tracker
end

function DetectionManager.calculateSpeed(self: DetectionManager, entity: DetectableEntity.DetectableEntity, distance: number): number
	-- 1. Get the base multiplier from the entity's status
	-- (Replacing the old STATUS_PRIORITIES and SPEED_MULTIPLIERS lookup)
	local speedMultiplier = entity:getDetectionMultiplier() 

	-- 2. "Quick Detection" Logic (From old line ~344)
	local QUICK_DETECTION_RANGE = 10
	local QUIK_DETECTION_MULTIPLIER = 3.33
	
	if distance <= QUICK_DETECTION_RANGE then
		speedMultiplier *= QUIK_DETECTION_MULTIPLIER
	end

	-- 3. Movement/WalkSpeed Multiplier (From old line ~333)
	-- If it's a player, we scale detection based on how fast they are moving
	local movementMult = entity:getMovementMultiplier() -- Should return 1.0 for static, or math.map for players
	speedMultiplier *= movementMult

	-- 4. Final Rate calculation (From old line ~350)
	-- BASE_DETECTION_TIME = 1.25
	local progressRate = (1 / 1.25) * speedMultiplier
	
	return progressRate
end

return DetectionManager