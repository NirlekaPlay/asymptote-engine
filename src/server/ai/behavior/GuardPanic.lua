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
		minDuration = math.huge,
		maxDuration = math.huge
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

	for playerStatus, player in pairs(susMan.detectedStatuses) do
		if ALARMING_STATUSES[playerStatus] then
			-- what the fuck.
			agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_PLAYER_SOURCE, player)
			agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_POSITION, player.Character.PrimaryPart.Position)
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
	local player = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_PLAYER_SOURCE):get()
	if agent:canBeIntimidated() and not agent:getBrain():hasMemoryValue(MemoryModuleTypes.LOOK_TARGET) then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.LOOK_TARGET, player)
	end
end

return GuardPanic