--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)

--[=[
	@class ReportMajorTrespasser
]=]
local ReportMajorTrespasser = {}
ReportMajorTrespasser.__index = ReportMajorTrespasser
ReportMajorTrespasser.ClassName = "ReportMajorTrespasser"

export type ReportMajorTrespasser = typeof(setmetatable({} :: {
}, ReportMajorTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReportMajorTrespasser.new(): ReportMajorTrespasser
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ReportMajorTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED
}

function ReportMajorTrespasser.getMemoryRequirements(self: ReportMajorTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportMajorTrespasser.checkExtraStartConditions(self: ReportMajorTrespasser, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local forStatus = PlayerStatusTypes.getStatusFromName(priorityEntity:getStatus())

			return forStatus == PlayerStatusTypes.MAJOR_TRESPASSING
		end)
		:isPresent()
end

function ReportMajorTrespasser.canStillUse(self: ReportMajorTrespasser, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		self:checkExtraStartConditions(agent)
end

function ReportMajorTrespasser.doStart(self: ReportMajorTrespasser, agent: Agent): ()
	local brain = agent:getBrain()
	local reportControl = agent:getReportControl()
	local talkControl = agent:getTalkControl()
	local faceControl = agent:getFaceControl()

	local detectedTrespasser = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local trespasserUuid = detectedTrespasser:getUuid()
	local trespasserEntity = EntityManager.getEntityByUuid(trespasserUuid)
	local trespasserPlayer = EntityUtils.getPlayerOrThrow(trespasserEntity)

	faceControl:setFace("Angry")

	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(trespasserPlayer)
	local reportDialogue
	if trespasserAreaName then
		reportDialogue = GuardGenericDialogues["trespassing.major.report.area.known"]
	else
		reportDialogue = GuardGenericDialogues["trespassing.major.report.area.unknown"]
	end

	local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
	local reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
	talkControl:saySequencesWithDelay(choosenDialogue, 0.5, trespasserAreaName)
	local reportRegisterDur = 3
	local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
	reportControl:reportWithCustomDur(
		ReportType.CRIMINAL_SPOTTED,
		reportRegisterDur,
		delayBeforeRadioUnequip
	)

	local targetableEntitiesMemory = brain:getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES):orElse({})
	targetableEntitiesMemory[trespasserPlayer] = true
	brain:setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntitiesMemory)
end

function ReportMajorTrespasser.doStop(self: ReportMajorTrespasser, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
end

function ReportMajorTrespasser.doUpdate(self: ReportMajorTrespasser, agent: Agent, deltaTime: number): ()
	return
end

function ReportMajorTrespasser.getReactionTime(self: ReportMajorTrespasser, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

return ReportMajorTrespasser