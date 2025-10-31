--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

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
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

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
	local detetectionManager = agent:getDetectionManager()
	local focusingTarget = detetectionManager:getFocusingTarget()
	if focusingTarget then
		-- TODO: Maybe prevent this from getting called repetedly
		local detLevel = detetectionManager:getDetectionLevel(focusingTarget.entityUuid)
		if not detLevel or detLevel < 1 then
			return false
		end
		return true
	end

	return false
end

function ValidateTrespasser.canStillUse(self: ValidateTrespasser, agent: Agent): boolean
	return false
end

function ValidateTrespasser.doStart(self: ValidateTrespasser, agent: Agent): ()
	local detetectionManager = agent:getDetectionManager()
	local focusingTarget = detetectionManager:getFocusingTarget()
	
	if focusingTarget then
		local status = focusingTarget.status
		-- "why. WHY. WHYYYY"
		-- I ask myself to past me.
		-- But for real, CONSISTENCY IN GETTING, COMPARING, AND STORING PLAYER STATUSES!!!
		if (status :: any) == PlayerStatusTypes.MINOR_TRESPASSING.name or
			(status :: any) == PlayerStatusTypes.MAJOR_TRESPASSING.name then
			local entity = EntityManager.getEntityByUuid(focusingTarget.entityUuid)
			if not entity or entity.name ~= "Player" or entity.isStatic == true then
				error("The fucking entity is not a valid Player or is nil. Non-players shouldnt even have trespassing statuses!!")
			end
			agent:getBrain():setNullableMemory(MemoryModuleTypes.SPOTTED_TRESPASSER, entity.instance)
		end
	else
		error("Strange, ValidateTrespasser:doStart() is called but focusing target is nil.")
	end
end

function ValidateTrespasser.doStop(self: ValidateTrespasser, agent: Agent): ()
	return
end

function ValidateTrespasser.doUpdate(self: ValidateTrespasser, agent: Agent, deltaTime: number): ()
	return
end

return ValidateTrespasser