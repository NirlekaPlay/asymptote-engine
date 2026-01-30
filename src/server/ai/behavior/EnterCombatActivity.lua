--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AlertLevels = require(ReplicatedStorage.shared.world.stealth.alertlevel.AlertLevels)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)

--[=[
	@class EnterCombatActivity
]=]
local EnterCombatActivity = {}
EnterCombatActivity.__index = EnterCombatActivity
EnterCombatActivity.ClassName = "EnterCombatActivity"

export type EnterCombatActivity = typeof(setmetatable({} :: {
}, EnterCombatActivity))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent

function EnterCombatActivity.new(): EnterCombatActivity
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, EnterCombatActivity)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.REGISTERED
}

function EnterCombatActivity.getMemoryRequirements(self: EnterCombatActivity): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function EnterCombatActivity.checkExtraStartConditions(self: EnterCombatActivity, agent: Agent): boolean
	return not agent:getReportControl():isReporting() and not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE)
end

function EnterCombatActivity.canStillUse(self: EnterCombatActivity, agent: Agent): boolean
	return false
end

function EnterCombatActivity.doStart(self: EnterCombatActivity, agent: Agent): ()
	if Mission.getAlertLevel() == AlertLevels.SEARCHING or
		Mission.getAlertLevel() == AlertLevels.LOCKDOWN then

		agent.character:SetAttribute("HearingRadius", 30)
		agent.character:SetAttribute("PeriphAngle", 360)
		agent.character:SetAttribute("SightRadius", 1024)
		
		agent:getBrain():setMemory(MemoryModuleTypes.IS_COMBAT_MODE, true)
		agent:getFaceControl():setFace("Angry")
		agent:getGunControl():equipGun()
		if agent:getGunControl():isEmpty() then
			agent:getGunControl():reload()
		end
		agent:getDetectionManager():blockAllDetection()
	end
end

function EnterCombatActivity.doStop(self: EnterCombatActivity, agent: Agent): ()
	return
end

function EnterCombatActivity.doUpdate(self: EnterCombatActivity, agent: Agent, deltaTime: number): ()
	return
end

function EnterCombatActivity.getReactionTime(self: EnterCombatActivity, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 2)
end

return EnterCombatActivity