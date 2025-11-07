--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PrioritizedEntity = require(ServerScriptService.server.ai.memory.PrioritizedEntity)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class ValidatePrioritizedEntity
]=]
local ValidatePrioritizedEntity = {}
ValidatePrioritizedEntity.__index = ValidatePrioritizedEntity
ValidatePrioritizedEntity.ClassName = "ValidatePrioritizedEntity"

export type ValidatePrioritizedEntity = typeof(setmetatable({} :: {
}, ValidatePrioritizedEntity))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function ValidatePrioritizedEntity.new(): ValidatePrioritizedEntity
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge
	}, ValidatePrioritizedEntity)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_INVESTIGATING] = MemoryStatus.REGISTERED
}

function ValidatePrioritizedEntity.getMemoryRequirements(self: ValidatePrioritizedEntity): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ValidatePrioritizedEntity.checkExtraStartConditions(self: ValidatePrioritizedEntity, agent: Agent): boolean
	return true
end

function ValidatePrioritizedEntity.canStillUse(self: ValidatePrioritizedEntity, agent: Agent): boolean
	return false
end

function ValidatePrioritizedEntity.doStart(self: ValidatePrioritizedEntity, agent: Agent): ()
	local fullyDetectedEntity = agent:getDetectionManager():getHighestFullyDetectedEntity()
	if fullyDetectedEntity then
		local isValid = ValidatePrioritizedEntity.isEntityValid(fullyDetectedEntity.entityUuid)
		local isInvestigating = agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_INVESTIGATING)
		if isValid and not isInvestigating then
			agent:getBrain():setMemory(MemoryModuleTypes.PRIORITIZED_ENTITY, PrioritizedEntity.new(
				fullyDetectedEntity.entityUuid,
				fullyDetectedEntity.status
			))
		end
	else
		agent:getBrain():eraseMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
	end
end

function ValidatePrioritizedEntity.doStop(self: ValidatePrioritizedEntity, agent: Agent): ()
	return
end

function ValidatePrioritizedEntity.doUpdate(self: ValidatePrioritizedEntity, agent: Agent, deltaTime: number): ()
	return
end

--

function ValidatePrioritizedEntity.isEntityValid(entityUuid: string): boolean
	local entity = EntityManager.getEntityByUuid(entityUuid)
	if not entity then
		return false
	end

	if not entity.isStatic and entity.name == "Player" and entity.instance:IsA("Player") then
		local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(entity.instance)
		if not playerStatusHolder then
			return false
		end

		return true
	else
		return true
	end
end

return ValidatePrioritizedEntity