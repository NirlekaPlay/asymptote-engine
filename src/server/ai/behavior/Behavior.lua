--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class Behavior

	Defines the interface of a Behavior.
]=]
local Behavior = {}
Behavior.__index = Behavior
Behavior.ClassName = "Behavior"

export type Behavior = typeof(setmetatable({} :: {
	read minDuration: number?,
	read maxDuration: number?
}, Behavior))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

local MEMORY_REQUIREMENTS = {}

function Behavior.getMemoryRequirements(self: Behavior): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS -- Return our static memory requirements here. Can also be non-static if required, but that's less performant
end

function Behavior.checkExtraStartConditions(self: Behavior, agent: Agent): boolean
	return true
end

function Behavior.canStillUse(self: Behavior, agent: Agent): boolean
	return false
end

function Behavior.doStart(self: Behavior, agent: Agent): ()
	return
end

function Behavior.doStop(self: Behavior, agent: Agent): ()
	return
end

function Behavior.doUpdate(self: Behavior, agent: Agent, deltaTime: number): ()
	return
end

return Behavior