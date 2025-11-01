--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class KillTargetableEntities
]=]
local KillTargetableEntities = {}
KillTargetableEntities.__index = KillTargetableEntities
KillTargetableEntities.ClassName = "KillTargetableEntities"

export type KillTargetableEntities = typeof(setmetatable({} :: {
}, KillTargetableEntities))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function KillTargetableEntities.new(): KillTargetableEntities
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, KillTargetableEntities)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT
}

function KillTargetableEntities.getMemoryRequirements(self: KillTargetableEntities): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function KillTargetableEntities.checkExtraStartConditions(self: KillTargetableEntities, agent: Agent): boolean
	return true
end

function KillTargetableEntities.canStillUse(self: KillTargetableEntities, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_INTIMIDATED)
end

function KillTargetableEntities.doStart(self: KillTargetableEntities, agent: Agent): ()
	return
end

function KillTargetableEntities.doStop(self: KillTargetableEntities, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.KILL_TARGET)
end

function KillTargetableEntities.doUpdate(self: KillTargetableEntities, agent: Agent, deltaTime: number): ()
	local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES):orElse({})
	local nearestTargetableEntity = self:getNearestTargetableEntity(agent, targetableEntities)
	if nearestTargetableEntity then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, nearestTargetableEntity)
	end
end

--

function KillTargetableEntities.getNearestTargetableEntity(
	self: KillTargetableEntities,
	agent: Agent,
	targetableEntities: { [Player]: true }
): Player

	local agentPos = agent:getPrimaryPart().Position
	local nearestEntity: Player
	local nearestDistance: number = math.huge

	for entity in targetableEntities do
		if not KillTargetableEntities.isEntityTargetable(entity) then
			continue
		end

		local primaryPart = (entity.Character :: Model).PrimaryPart :: BasePart -- already checked
		local distance = (primaryPart.Position - agentPos).Magnitude
		if distance < nearestDistance then
			nearestEntity = entity
			nearestDistance = distance
		end
	end

	return nearestEntity
end

function KillTargetableEntities.isEntityTargetable(entity: Player): boolean
	if not (entity.Character and entity.Character.PrimaryPart) then
		return false
	end

	local humanoid = entity.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true
end

return KillTargetableEntities