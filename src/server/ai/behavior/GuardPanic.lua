--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)

--[=[
	@class GuardPanic
]=]
local GuardPanic = {}
GuardPanic.__index = GuardPanic
GuardPanic.ClassName = "GuardPanic"

export type GuardPanic = typeof(setmetatable({} :: {
}, GuardPanic))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function GuardPanic.new(): GuardPanic
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, GuardPanic)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.REGISTERED
}

local ALARMING_STATUSES: { [ PlayerStatus.PlayerStatusType ]: true } = {
	["ARMED"] = true,
	["DANGEROUS_ITEM"] = true
}

function GuardPanic.getMemoryRequirements(self: GuardPanic): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function GuardPanic.checkExtraStartConditions(self: GuardPanic, agent: Agent): boolean
	local susMan = agent:getSuspicionManager()

	for player, playerStatus in pairs(susMan.detectionLocks) do
		if ALARMING_STATUSES[playerStatus] then
			return true
		end
	end

	return false
end

function GuardPanic.canStillUse(self: GuardPanic, agent: Agent): boolean
	return true
end

function GuardPanic.doStart(self: GuardPanic, agent: Agent): ()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_PANICKING, true)
end

function GuardPanic.doStop(self: GuardPanic, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.IS_PANICKING)
end

function GuardPanic.doUpdate(self: GuardPanic, agent: Agent, deltaTime: number): ()
	return
end

return GuardPanic