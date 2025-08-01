--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class DummyBehavior
]=]
local DummyBehavior = {}
DummyBehavior.__index = DummyBehavior
DummyBehavior.ClassName = "DummyBehavior"

export type DummyBehavior = typeof(setmetatable({} :: {
}, DummyBehavior))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function DummyBehavior.new(): DummyBehavior
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, DummyBehavior)
end

local MEMORY_REQUIREMENTS = {}

function DummyBehavior.getMemoryRequirements(self: DummyBehavior): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function DummyBehavior.checkExtraStartConditions(self: DummyBehavior, agent: Agent): boolean
	return true
end

function DummyBehavior.canStillUse(self: DummyBehavior, agent: Agent): boolean
	return false
end

function DummyBehavior.doStart(self: DummyBehavior, agent: Agent): ()
	print("DummyBehavior::doStart() called")
end

function DummyBehavior.doStop(self: DummyBehavior, agent: Agent): ()
	print("DummyBehavior::doStop() called")
end

function DummyBehavior.doUpdate(self: DummyBehavior, agent: Agent, deltaTime: number): ()
	print("DummyBehavior::doUpdate() called")
end

return DummyBehavior