--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class SetPanicFace
]=]
local SetPanicFace = {}
SetPanicFace.__index = SetPanicFace
SetPanicFace.ClassName = "SetPanicFace"

export type SetPanicFace = typeof(setmetatable({} :: {
}, SetPanicFace))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function SetPanicFace.new(): SetPanicFace
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, SetPanicFace)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_CURIOUS] = MemoryStatus.REGISTERED
}

function SetPanicFace.getMemoryRequirements(self: SetPanicFace): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function SetPanicFace.checkExtraStartConditions(self: SetPanicFace, agent: Agent): boolean
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING)
end

function SetPanicFace.canStillUse(self: SetPanicFace, agent: Agent): boolean
	return self:checkExtraStartConditions(agent)
end

function SetPanicFace.doStart(self: SetPanicFace, agent: Agent): ()
	agent:getFaceControl():setFace("Shocked")
end

function SetPanicFace.doStop(self: SetPanicFace, agent: Agent): ()
	agent:getFaceControl():setFace("Neutral")
end

function SetPanicFace.doUpdate(self: SetPanicFace, agent: Agent, deltaTime: number): ()
	return
end

return SetPanicFace