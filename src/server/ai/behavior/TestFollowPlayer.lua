--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)

--[=[
	@class TestFollowPlayer
]=]
local TestFollowPlayer = {}
TestFollowPlayer.__index = TestFollowPlayer
TestFollowPlayer.ClassName = "TestFollowPlayer"

export type TestFollowPlayer = typeof(setmetatable({} :: {
}, TestFollowPlayer))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function TestFollowPlayer.new(): TestFollowPlayer
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge
	}, TestFollowPlayer)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.WALK_TARGET] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT
}

function TestFollowPlayer.getMemoryRequirements(self: TestFollowPlayer): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function TestFollowPlayer.checkExtraStartConditions(self: TestFollowPlayer, agent: Agent): boolean
	return true
end

function TestFollowPlayer.canStillUse(self: TestFollowPlayer, agent: Agent): boolean
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.WALK_TARGET)
end

function TestFollowPlayer.doStart(self: TestFollowPlayer, agent: Agent): ()
	agent:getBrain():setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromPlayer(EntityUtils.getPlayerOrThrow(EntityManager.getEntityByUuid(agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get():getUuid())), 1, 7))
end

function TestFollowPlayer.doStop(self: TestFollowPlayer, agent: Agent): ()
	return
end

function TestFollowPlayer.doUpdate(self: TestFollowPlayer, agent: Agent, deltaTime: number): ()
	return
end

return TestFollowPlayer