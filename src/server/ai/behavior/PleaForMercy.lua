--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class PleaForMercy
]=]
local PleaForMercy = {}
PleaForMercy.__index = PleaForMercy
PleaForMercy.ClassName = "PleaForMercy"

export type PleaForMercy = typeof(setmetatable({} :: {
	alreadyRun: boolean
}, PleaForMercy))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function PleaForMercy.new(): PleaForMercy
	return setmetatable({
		minDuration = 1,
		maxDuration = 1,
		alreadyRun = false
	}, PleaForMercy)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT
	--[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_PRESENT
}

function PleaForMercy.getMemoryRequirements(self: PleaForMercy): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function PleaForMercy.checkExtraStartConditions(self: PleaForMercy, agent: Agent): boolean
	return not self.alreadyRun
end

function PleaForMercy.canStillUse(self: PleaForMercy, agent: Agent): boolean
	return false
end

function PleaForMercy.doStart(self: PleaForMercy, agent: Agent): ()
	self.alreadyRun = true
	agent:getTalkControl():saySequences({"Wait wait wait!", "Don't shoot!"})
end

function PleaForMercy.doStop(self: PleaForMercy, agent: Agent): ()
	return
end

function PleaForMercy.doUpdate(self: PleaForMercy, agent: Agent, deltaTime: number): ()
	return
end

return PleaForMercy