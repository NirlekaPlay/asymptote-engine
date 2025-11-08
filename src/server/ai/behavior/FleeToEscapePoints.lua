--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugEntityNameGenerator = require(ReplicatedStorage.shared.network.DebugEntityNameGenerator)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local Level = require(ServerScriptService.server.world.level.Level)

local DEBUG_MODE = false
local MIN_DISTANCE_TO_ESCAPE_POS = 5
local DIST_CHECK_UPDATE_INTERVAL = 0.5

local rng = Random.new(tick())

--[=[
	@class FleeToEscapePoints
]=]
local FleeToEscapePoints = {}
FleeToEscapePoints.__index = FleeToEscapePoints
FleeToEscapePoints.ClassName = "FleeToEscapePoints"

export type FleeToEscapePoints = typeof(setmetatable({} :: {
	timeAccum: number
}, FleeToEscapePoints))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent

function FleeToEscapePoints.new(): FleeToEscapePoints
	return setmetatable({
		minDuration = 3,
		maxDuration = 5,
		timeAccum = 0
	}, FleeToEscapePoints)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_FLEEING] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.DESIGNATED_POSTS] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.PANIC_POSITION] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.HAS_FLED] = MemoryStatus.VALUE_ABSENT
}

function FleeToEscapePoints.getMemoryRequirements(self: FleeToEscapePoints): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function FleeToEscapePoints.checkExtraStartConditions(self: FleeToEscapePoints, agent: Agent): boolean
	return true
end

function FleeToEscapePoints.canStillUse(self: FleeToEscapePoints, agent: Agent): boolean
	return not (agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_INTIMIDATED)
		or agent:getBrain():hasMemoryValue(MemoryModuleTypes.KILL_TARGET))
end

function FleeToEscapePoints.doStart(self: FleeToEscapePoints, agent: Agent): ()
	local post = self:chooseEscapePoint(agent, agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get(), Level.getGuardCombatNodes())
	if post then
		agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
		agent:getNavigation():setToRunningSpeed()
		agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, true)
		agent:getNavigation():moveTo(post.cframe.Position)
		agent:getBrain():setNullableMemory(MemoryModuleTypes.FLEE_TO_POSITION, post.cframe.Position)
		if DEBUG_MODE then
			Debris:AddItem(Draw.point(post.cframe.Position, Color3.new(0, 1, 0)), 5)
		end
	else
		local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
		if not panicSourceTargetToKill:isPresent() then
			return
		end
		local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
		if not entityObj then
			error("Panic source entity is nil")
		end
		if not entityObj.isStatic and entityObj.name == "Player" then
			local player = Players:GetPlayerByUserId(tonumber(entityObj.uuid) :: number)
			local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
				:orElse({})

			targetableEntities[player] = true
			agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
		end
	end
end

local function reflect(direction: Vector3, normal: Vector3): Vector3
	return direction - 2 * direction:Dot(normal) * normal
end

function FleeToEscapePoints.doStop(self: FleeToEscapePoints, agent: Agent): ()
	-- Breaks DRY!!!!
	local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
	if not panicSourceTargetToKill:isPresent() then
		return
	end
	local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
	if not entityObj then
		error("Panic source entity is nil")
	end
	if not entityObj.isStatic and entityObj.name == "Player" then
		local player = Players:GetPlayerByUserId(entityObj.uuid)
		local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
				:orElse({})

		targetableEntities[player] = true
		agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
	end
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, false)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.HAS_FLED, true)
	agent:getNavigation():stop()
	agent:getFaceControl():setFace("Angry")

	--[[local maxDistance = 25
	local panicPos = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get()
	local agentPos = agent:getPrimaryPart().Position
	local direction = (panicPos - agentPos).Unit
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { agent.character }
	local rayResult = workspace:Raycast(agentPos, direction * maxDistance, rayParams)
	if not rayResult then
		agent:getGunControl():lookAt(panicPos)
		agent:getBodyRotationControl():setRotateTowards(panicPos)
		Debris:AddItem(Draw.raycast(agentPos, direction * maxDistance), 15)
	else
		local reflectedDirection = reflect(direction, rayResult.Normal).Unit
		local distanceToHit = (agentPos - rayResult.Position).Magnitude
		local distanceDifference = maxDistance - distanceToHit
		local finalPos = rayResult.Position + reflectedDirection * distanceDifference
		agent:getGunControl():lookAt(finalPos)
		agent:getBodyRotationControl():setRotateTowards(finalPos)

		Debris:AddItem(Draw.line(agentPos, rayResult.Position, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.line(rayResult.Position, finalPos, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.point(finalPos, Color3.new(0.968627, 0, 1)), 15)
	end]]
end

function FleeToEscapePoints.doUpdate(self: FleeToEscapePoints, agent: Agent, deltaTime: number): ()
	self.timeAccum += deltaTime
	if self.timeAccum >= DIST_CHECK_UPDATE_INTERVAL then
		self.timeAccum = 0

		local fleeToPos = agent:getBrain():getMemory(MemoryModuleTypes.FLEE_TO_POSITION)
		if fleeToPos:isEmpty() then
			print("flee to pos is empty")
			return
		end

		local distance = (agent:getPrimaryPart().Position - fleeToPos:get()).Magnitude
		if distance <= MIN_DISTANCE_TO_ESCAPE_POS then
			print(`{DebugEntityNameGenerator.getEntityName(agent)} is in minimum distance to escape point position \n with distance of {distance}`)
			local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
			if not panicSourceTargetToKill:isPresent() then
				return
			end
			local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
			if not entityObj then
				error("Panic source entity is nil")
			end
			if not entityObj.isStatic and entityObj.name == "Player" then
				local player = Players:GetPlayerByUserId(entityObj.uuid)
				local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
					:orElse({})

				targetableEntities[player] = true

				agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
			end
		end
	end
end

--

local WEIGHT_DISTANCE = 1.0          -- weight for distance from threat
local WEIGHT_THREAT_EXPOSURE = 1.5   -- weight for threat exposure
local WEIGHT_PATH_COST = 0.5         -- weight for path cost

function FleeToEscapePoints.chooseEscapePoint(
	self: FleeToEscapePoints,
	agent: Agent,
	panicSourcePos: Vector3,
	escapePoints: {Node.Node}
): Node.Node?
	local bestScore = -math.huge
	local choosenEscapePoint: Node.Node? = nil

	for _, post in escapePoints do
		local path = agent:getNavigation():generatePath(post.cframe.Position)
		if not path then
			continue
		end

		local waypoints = path:GetWaypoints()

		local distance = (post.cframe.Position - panicSourcePos).Magnitude
		local threatExposure = FleeToEscapePoints.getWaypointsThreatExposure(waypoints, panicSourcePos)
		local pathCost = FleeToEscapePoints.getWaypointsPathLength(waypoints)
		local randomSalt = rng:NextInteger(1, 5)

		local score = WEIGHT_DISTANCE * distance - WEIGHT_THREAT_EXPOSURE * threatExposure - WEIGHT_PATH_COST * pathCost + randomSalt
		if score > bestScore then
			bestScore = score
			choosenEscapePoint = post
		end
	end

	return choosenEscapePoint
end

function FleeToEscapePoints.getWaypointsThreatExposure(waypoints: {PathWaypoint}, panicSourcePos: Vector3): number
	local minDistToThreat = math.huge
	for _, point in ipairs(waypoints) do
		local dist = (point.Position - panicSourcePos).Magnitude
		if dist < minDistToThreat then
			minDistToThreat = dist
		end
	end

	return 1 / (minDistToThreat + 0.001) -- closer paths get higher threat
end

function FleeToEscapePoints.getWaypointsPathLength(waypoints: {PathWaypoint}): number
	local pathCost = 0
	for i = 2, #waypoints do
		pathCost = pathCost + (waypoints[i].Position - waypoints[i-1].Position).Magnitude
	end
	return pathCost
end

return FleeToEscapePoints