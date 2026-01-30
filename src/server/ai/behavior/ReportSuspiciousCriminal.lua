--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.world.stealth.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)

--[=[
	@class ReportSuspiciousCriminal
]=]
local ReportSuspiciousCriminal = {}
ReportSuspiciousCriminal.__index = ReportSuspiciousCriminal
ReportSuspiciousCriminal.ClassName = "ReportSuspiciousCriminal"

export type ReportSuspiciousCriminal = typeof(setmetatable({} :: {
}, ReportSuspiciousCriminal))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReportSuspiciousCriminal.new(): ReportSuspiciousCriminal
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ReportSuspiciousCriminal)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED
}

function ReportSuspiciousCriminal.getMemoryRequirements(self: ReportSuspiciousCriminal): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportSuspiciousCriminal.checkExtraStartConditions(self: ReportSuspiciousCriminal, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local forStatus = PlayerStatusTypes.getStatusFromName(priorityEntity:getStatus())
			return forStatus == PlayerStatusTypes.CRIMINAL_SUSPICIOUS
		end)
		:isPresent()
end

function ReportSuspiciousCriminal.canStillUse(self: ReportSuspiciousCriminal, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		self:checkExtraStartConditions(agent)
end

function ReportSuspiciousCriminal.doStart(self: ReportSuspiciousCriminal, agent: Agent): ()
	local brain = agent:getBrain()
	local reportCtrl = agent:getReportControl()
	local talkCtrl = agent:getTalkControl()
	local faceCtrl = agent:getFaceControl()

	local criminal = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local criminalUuid = criminal:getUuid()
	local criminalEntity = EntityManager.getEntityByUuid(criminalUuid)
	local criminalPlayer = EntityUtils.getPlayerOrThrow(criminalEntity)
	local criminalCurrentArea = agent:getServerLevel():getCellManager():getPlayerOccupiedAreaName(criminalPlayer)
	local reportDialogue
	if criminalCurrentArea then
		reportDialogue = GuardGenericDialogues["status.sus_criminal.area.known"]
	else
		reportDialogue = GuardGenericDialogues["status.sus_criminal.area.unknown"]
	end

	reportDialogue = talkCtrl.randomlyChosoeDialogueSequences(reportDialogue)

	faceCtrl:setFace("Angry")
	talkCtrl:saySequences(reportDialogue, criminalCurrentArea)
	reportCtrl:reportWithCustomDur(ReportType.CRIMINAL_SPOTTED, 2, talkCtrl.getDialoguesTotalSpeechDuration(reportDialogue :: any))

	local targetableEntitiesMemory = brain:getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES):orElse({})
	targetableEntitiesMemory[criminalPlayer] = true
	brain:setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntitiesMemory)
end

function ReportSuspiciousCriminal.doStop(self: ReportSuspiciousCriminal, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
end

function ReportSuspiciousCriminal.doUpdate(self: ReportSuspiciousCriminal, agent: Agent, deltaTime: number): ()
	return
end

function ReportSuspiciousCriminal.getReactionTime(self: ReportSuspiciousCriminal, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

return ReportSuspiciousCriminal