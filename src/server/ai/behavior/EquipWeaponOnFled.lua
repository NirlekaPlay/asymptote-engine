--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class EquipWeaponOnFled
]=]
local EquipWeaponOnFled = {}
EquipWeaponOnFled.__index = EquipWeaponOnFled
EquipWeaponOnFled.ClassName = "EquipWeaponOnFled"

export type EquipWeaponOnFled = typeof(setmetatable({} :: {
}, EquipWeaponOnFled))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent

function EquipWeaponOnFled.new(): EquipWeaponOnFled
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, EquipWeaponOnFled)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.HAS_FLED] = MemoryStatus.VALUE_PRESENT
}

function EquipWeaponOnFled.getMemoryRequirements(self: EquipWeaponOnFled): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function EquipWeaponOnFled.checkExtraStartConditions(self: EquipWeaponOnFled, agent: Agent): boolean
	return true
end

function EquipWeaponOnFled.canStillUse(self: EquipWeaponOnFled, agent: Agent): boolean
	return false
end

function EquipWeaponOnFled.doStart(self: EquipWeaponOnFled, agent: Agent): ()
	agent:getGunControl():equipGun()
end

function EquipWeaponOnFled.doStop(self: EquipWeaponOnFled, agent: Agent): ()
	return
end

function EquipWeaponOnFled.doUpdate(self: EquipWeaponOnFled, agent: Agent, deltaTime: number): ()
	return
end

return EquipWeaponOnFled