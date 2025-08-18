--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)

--[=[
	@class ValidateTrespasser
]=]
local ValidateTrespasser = {}
ValidateTrespasser.__index = ValidateTrespasser
ValidateTrespasser.ClassName = "ValidateTrespasser"

export type ValidateTrespasser = typeof(setmetatable({} :: {
}, ValidateTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function ValidateTrespasser.new(): ValidateTrespasser
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ValidateTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.SPOTTED_TRESPASSER] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.KILL_TARGET] = MemoryStatus.VALUE_ABSENT
}

function ValidateTrespasser.getMemoryRequirements(self: ValidateTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ValidateTrespasser.checkExtraStartConditions(self: ValidateTrespasser, agent: Agent): boolean
	for status, player in pairs(agent:getSuspicionManager().detectedStatuses) do
		if status == "MINOR_TRESPASSING" then
			return true
		end
	end

	return true
end

function ValidateTrespasser.canStillUse(self: ValidateTrespasser, agent: Agent): boolean
	return false
end

function ValidateTrespasser.doStart(self: ValidateTrespasser, agent: Agent): ()
	local highestStatus: PlayerStatus.PlayerStatusType?
	local player: Player?
	local highestPriority = -math.huge

	for status, plr in pairs(agent:getSuspicionManager().detectedStatuses) do
		local statusPriority = PlayerStatus.getStatusPriorityValue(status)

		if statusPriority > highestPriority then
			highestPriority = statusPriority
			highestStatus = status
			player = plr
		end
	end

	if highestStatus and highestStatus == "MINOR_TRESPASSING" then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.SPOTTED_TRESPASSER, player)
	else
		agent:getBrain():setNullableMemory(MemoryModuleTypes.SPOTTED_TRESPASSER, nil)
	end
end

function ValidateTrespasser.doStop(self: ValidateTrespasser, agent: Agent): ()
	return
end

function ValidateTrespasser.doUpdate(self: ValidateTrespasser, agent: Agent, deltaTime: number): ()
	return
end

return ValidateTrespasser