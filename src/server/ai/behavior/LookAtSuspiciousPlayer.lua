--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class LookAtSuspiciousPlayer
]=]
local LookAtSuspiciousPlayer = {}
LookAtSuspiciousPlayer.__index = LookAtSuspiciousPlayer
LookAtSuspiciousPlayer.ClassName = "LookAtSuspiciousPlayer"

export type LookAtSuspiciousPlayer = typeof(setmetatable({} :: {
}, LookAtSuspiciousPlayer))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function LookAtSuspiciousPlayer.new(): LookAtSuspiciousPlayer
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, LookAtSuspiciousPlayer)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.REGISTERED
}

function LookAtSuspiciousPlayer.getMemoryRequirements(self: LookAtSuspiciousPlayer): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function LookAtSuspiciousPlayer.checkExtraStartConditions(self: LookAtSuspiciousPlayer, agent: Agent): boolean
	return agent:getSuspicionManager():isCurious()
end

function LookAtSuspiciousPlayer.canStillUse(self: LookAtSuspiciousPlayer, agent: Agent): boolean
	return self:checkExtraStartConditions(agent) 
end

function LookAtSuspiciousPlayer.doStart(self: LookAtSuspiciousPlayer, agent: Agent): ()
	return
end

function LookAtSuspiciousPlayer.doStop(self: LookAtSuspiciousPlayer, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
end

function LookAtSuspiciousPlayer.doUpdate(self: LookAtSuspiciousPlayer, agent: Agent, deltaTime: number): ()
	local suspect = agent:getSuspicionManager():getFocusingTarget()
	if suspect ~= nil then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.LOOK_TARGET, suspect)
	end
end

return LookAtSuspiciousPlayer