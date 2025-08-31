--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class SetIsCuriousMemory

	Defines the interface of a SetIsCuriousMemory.
]=]
local SetIsCuriousMemory = {}
SetIsCuriousMemory.__index = SetIsCuriousMemory
SetIsCuriousMemory.ClassName = "SetIsCuriousMemory"

export type SetIsCuriousMemory = typeof(setmetatable({} :: {
}, SetIsCuriousMemory))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function SetIsCuriousMemory.new(): SetIsCuriousMemory
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, SetIsCuriousMemory)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_CURIOUS] = MemoryStatus.REGISTERED
}

function SetIsCuriousMemory.getMemoryRequirements(self: SetIsCuriousMemory): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function SetIsCuriousMemory.checkExtraStartConditions(self: SetIsCuriousMemory, agent: Agent): boolean
	return agent:getSuspicionManager():isCurious()
end

function SetIsCuriousMemory.canStillUse(self: SetIsCuriousMemory, agent: Agent): boolean
	return self:checkExtraStartConditions(agent)
end

function SetIsCuriousMemory.doStart(self: SetIsCuriousMemory, agent: Agent): ()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_CURIOUS, true)
end

function SetIsCuriousMemory.doStop(self: SetIsCuriousMemory, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.IS_CURIOUS)
end

function SetIsCuriousMemory.doUpdate(self: SetIsCuriousMemory, agent: Agent, deltaTime: number): ()
	return
end

return SetIsCuriousMemory