--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local Level = require(ServerScriptService.server.world.level.Level)

local DEBUG_MODE = false
local RUN_SPEED_MODIFIER = 2.5

local rng = Random.new()

--[=[
	@class FleeToEscapePoints
]=]
local FleeToEscapePoints = {}
FleeToEscapePoints.__index = FleeToEscapePoints
FleeToEscapePoints.ClassName = "FleeToEscapePoints"

export type FleeToEscapePoints = typeof(setmetatable({} :: {
	calculatingBestEscapePoint: boolean
}, FleeToEscapePoints))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent

function FleeToEscapePoints.new(): FleeToEscapePoints
	return setmetatable({
		minDuration = 3,
		maxDuration = 5,
		calculatingBestEscapePoint = true
	}, FleeToEscapePoints)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_FLEEING] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.PANIC_POSITION] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.HAS_FLED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.KILL_TARGET] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.FLEE_TO_POSITION] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.WALK_TARGET] = MemoryStatus.REGISTERED
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
		agent:getBrain():setMemory(MemoryModuleTypes.IS_FLEEING, true)
		agent:getBrain():setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromVector3(post.cframe.Position, RUN_SPEED_MODIFIER, 2))
		agent:getBrain():setMemory(MemoryModuleTypes.FLEE_TO_POSITION, post.cframe.Position)
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

		local playerThreat = EntityUtils.ifPlayerThenGet(entityObj)
		if playerThreat then
			local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
				:orElse({})

			targetableEntities[playerThreat] = true
			agent:getBrain():setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
		end
	end
end

function FleeToEscapePoints.doStop(self: FleeToEscapePoints, agent: Agent): ()
	local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
	if not panicSourceTargetToKill:isPresent() then
		return
	end

	local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
	if not entityObj then
		error("Panic source entity is nil")
	end

	local playerThreat = EntityUtils.ifPlayerThenGet(entityObj)
	if playerThreat then
		local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
				:orElse({})

		targetableEntities[playerThreat] = true
		agent:getBrain():setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
	end

	agent:getBrain():setMemory(MemoryModuleTypes.IS_FLEEING, false)
	agent:getBrain():setMemory(MemoryModuleTypes.HAS_FLED, true)
	agent:getBrain():eraseMemory(MemoryModuleTypes.WALK_TARGET)
	agent:getFaceControl():setFace("Angry")
end

function FleeToEscapePoints.doUpdate(self: FleeToEscapePoints, agent: Agent, deltaTime: number): ()
	if self.calculatingBestEscapePoint then
		return
	end

	if agent:getBrain():hasMemoryValue(MemoryModuleTypes.WALK_TARGET) then
		return
	end

	local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
	if not panicSourceTargetToKill:isPresent() then
		return
	end

	local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
	if not entityObj then
		error("Panic source entity is nil")
	end

	local playerThreat = EntityUtils.ifPlayerThenGet(entityObj)
	if playerThreat then
		local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
			:orElse({})

		targetableEntities[playerThreat] = true

		agent:getBrain():setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
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
	self.calculatingBestEscapePoint = true

	local bestScore = -math.huge
	local choosenEscapePoint: Node.Node? = nil

	for _, post in escapePoints do
		if not agent:isAlive() then
			return nil
		end

		local path = agent:getNavigation():createPathAsync(post.cframe.Position)
		if not path then
			continue
		end

		local waypoints = path:getWaypoints()

		local distance = (post.cframe.Position - panicSourcePos).Magnitude
		local threatExposure = FleeToEscapePoints.getWaypointsThreatExposure(waypoints, panicSourcePos)
		local pathCost = path:getTotalLength()
		local randomSalt = rng:NextInteger(1, 5)

		local score = WEIGHT_DISTANCE * distance - WEIGHT_THREAT_EXPOSURE * threatExposure - WEIGHT_PATH_COST * pathCost + randomSalt
		if score > bestScore then
			bestScore = score
			choosenEscapePoint = post
		end
	end

	self.calculatingBestEscapePoint = false

	return choosenEscapePoint
end

function FleeToEscapePoints.getWaypointsThreatExposure(waypoints: {PathWaypoint}, panicSourcePos: Vector3): number
	local minDistToThreat = math.huge
	for _, point in waypoints do
		local dist = (point.Position - panicSourcePos).Magnitude
		if dist < minDistToThreat then
			minDistToThreat = dist
		end
	end

	return 1 / (minDistToThreat + 0.001) -- closer paths get higher threat
end


-- Unused stuff, stored cuz we may need it later, or not, who knows

local function reflect(direction: Vector3, normal: Vector3): Vector3
	return direction - 2 * direction:Dot(normal) * normal
end

function FleeToEscapePoints.avoidLookAtWalls(agent: Agent): ()
	local maxDistance = 25
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
		if DEBUG_MODE then
			Debris:AddItem(Draw.raycast(agentPos, direction * maxDistance), 15)
		end
	else
		local reflectedDirection = reflect(direction, rayResult.Normal).Unit
		local distanceToHit = (agentPos - rayResult.Position).Magnitude
		local distanceDifference = maxDistance - distanceToHit
		local finalPos = rayResult.Position + reflectedDirection * distanceDifference
		agent:getGunControl():lookAt(finalPos)
		agent:getBodyRotationControl():setRotateTowards(finalPos)

		if DEBUG_MODE then
			Debris:AddItem(Draw.line(agentPos, rayResult.Position, Color3.new(0.184314, 0, 1)), 15)
			Debris:AddItem(Draw.line(rayResult.Position, finalPos, Color3.new(0.184314, 0, 1)), 15)
			Debris:AddItem(Draw.point(finalPos, Color3.new(0.968627, 0, 1)), 15)
		end
	end
end

return FleeToEscapePoints