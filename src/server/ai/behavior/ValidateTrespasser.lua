--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

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
	[MemoryModuleTypes.CONFRONTING_TRESPASSER] = MemoryStatus.REGISTERED
}

function ValidateTrespasser.getMemoryRequirements(self: ValidateTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ValidateTrespasser.checkExtraStartConditions(self: ValidateTrespasser, agent: Agent): boolean
	return true
end

function ValidateTrespasser.canStillUse(self: ValidateTrespasser, agent: Agent): boolean
	return false
end

function ValidateTrespasser.doStart(self: ValidateTrespasser, agent: Agent): ()
	print("ValidateTrespasser::doStart() called")
end

function ValidateTrespasser.doStop(self: ValidateTrespasser, agent: Agent): ()
	print("ValidateTrespasser::doStop() called")
end

function ValidateTrespasser.doUpdate(self: ValidateTrespasser, agent: Agent, deltaTime: number): ()
	print("ValidateTrespasser::doUpdate() called")
end

return ValidateTrespasser