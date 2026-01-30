--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local ReportType = require(ReplicatedStorage.shared.world.stealth.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

--[=[
	@class ReportDeadBody
]=]
local ReportDeadBody = {}
ReportDeadBody.__index = ReportDeadBody
ReportDeadBody.ClassName = "ReportDeadBody"

export type ReportDeadBody = typeof(setmetatable({} :: {
}, ReportDeadBody))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReportDeadBody.new(): ReportDeadBody
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ReportDeadBody)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT
}

function ReportDeadBody.getMemoryRequirements(self: ReportDeadBody): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportDeadBody.checkExtraStartConditions(self: ReportDeadBody, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			return priorityEntity.forStatus == "DeadBodies"
		end)
		:isPresent()
end

function ReportDeadBody.canStillUse(self: ReportDeadBody, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		self:checkExtraStartConditions(agent)
end

function ReportDeadBody.doStart(self: ReportDeadBody, agent: Agent): ()
	local reportControl = agent:getReportControl()
	local talkControl = agent:getTalkControl()
	local faceControl = agent:getFaceControl()

	local deadBody = agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()

	faceControl:setFace("Angry")

	local reportDialogue
	local deadBodyName = nil
	if ReportDeadBody.doesRecogniseBody(agent, deadBody:getUuid()) then
		deadBodyName = ReportDeadBody.getBodyName(deadBody:getUuid())
		reportDialogue = GuardGenericDialogues["entity.dead_body_known"]
	else
		reportDialogue = GuardGenericDialogues["entity.dead_body_unknown"]
	end

	local choosenDialogue = talkControl.randomlyChooseDialogueSequences(reportDialogue)
	local reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
	talkControl:saySequencesWithDelay(choosenDialogue, 0.5, deadBodyName)
	local reportRegisterDur = 3
	local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
	reportControl:reportWithCustomDur(
		ReportType.BODY_FOUND,
		reportRegisterDur,
		delayBeforeRadioUnequip
	)
end

function ReportDeadBody.doStop(self: ReportDeadBody, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
end

function ReportDeadBody.doUpdate(self: ReportDeadBody, agent: Agent, deltaTime: number): ()
	return
end

function ReportDeadBody.getReactionTime(self: ReportDeadBody, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

--

function ReportDeadBody.doesRecogniseBody(agent: Agent, uuid: string): boolean
	return true
end

function ReportDeadBody.getBodyName(uuid: string): string
	local char = (EntityManager.getEntityByUuid(uuid) :: EntityManager.DynamicEntity).instance :: { Humanoid: Humanoid } & Model
	return char.Humanoid.DisplayName
end

return ReportDeadBody