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

--[=[
	@class ReportSuspiciousPlayer
]=]
local ReportSuspiciousPlayer = {}
ReportSuspiciousPlayer.__index = ReportSuspiciousPlayer
ReportSuspiciousPlayer.ClassName = "ReportSuspiciousPlayer"

local BUFFER_TIME = 1

export type ReportSuspiciousPlayer = typeof(setmetatable({} :: {
	talkingBufferTimeAccum: number,
	reportingBufferTimeAccum: number,
	reactionDialogueTime: number,
	reportInitiated: boolean
}, ReportSuspiciousPlayer))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReportSuspiciousPlayer.new(): ReportSuspiciousPlayer
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		talkingBufferTimeAccum = 0,
		reportingBufferTimeAccum = 0,
		reactionDialogueTime = 0,
		reportInitiated = false
	}, ReportSuspiciousPlayer)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED
}

function ReportSuspiciousPlayer.getMemoryRequirements(self: ReportSuspiciousPlayer): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportSuspiciousPlayer.checkExtraStartConditions(self: ReportSuspiciousPlayer, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local forStatus = PlayerStatusTypes.getStatusFromName(priorityEntity:getStatus())
			return forStatus == PlayerStatusTypes.MINOR_SUSPICIOUS
		end)
		:isPresent()
end

function ReportSuspiciousPlayer.canStillUse(self: ReportSuspiciousPlayer, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		self:checkExtraStartConditions(agent)
end

function ReportSuspiciousPlayer.doStart(self: ReportSuspiciousPlayer, agent: Agent): ()
	local talkCtrl = agent:getTalkControl()
	local faceCtrl = agent:getFaceControl()
	local dialogue = GuardGenericDialogues["status.sus_minor.reaction"]

	dialogue = talkCtrl.randomlyChooseDialogueSequences(dialogue)

	faceCtrl:setFace("Angry")
	talkCtrl:saySequences(dialogue)

	self.talkingBufferTimeAccum = 0
	self.reportingBufferTimeAccum = 0
	self.reactionDialogueTime = talkCtrl.getDialoguesTotalSpeechDuration(dialogue) + BUFFER_TIME
end

function ReportSuspiciousPlayer.doStop(self: ReportSuspiciousPlayer, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()

	self.talkingBufferTimeAccum = 0
	self.reportingBufferTimeAccum = 0
	self.reactionDialogueTime = 0
end

function ReportSuspiciousPlayer.doUpdate(self: ReportSuspiciousPlayer, agent: Agent, deltaTime: number): ()
	if self.talkingBufferTimeAccum < self.reactionDialogueTime then
		self.talkingBufferTimeAccum += deltaTime
		return
	end

	if not self.reportInitiated then
		local talkControl = agent:getTalkControl()

		local reportDialogue
		local reportDialogueSpeechDur: number
		local reportRegisterDur = 2.5

		reportDialogue = GuardGenericDialogues["status.sus_minor.report"]
		local choosenDialogue = talkControl.randomlyChooseDialogueSequences(reportDialogue)
		reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
		talkControl:saySequencesWithDelay(choosenDialogue, 0.5)

		local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
		agent:getReportControl():reportWithCustomDur(
			ReportType.SUSPICIOUS_PERSON,
			reportRegisterDur,
			delayBeforeRadioUnequip
		)

		self.reportingBufferTimeAccum = reportDialogueSpeechDur + delayBeforeRadioUnequip + BUFFER_TIME 
		-- NOTE: The new buffer duration should cover the entire reporting sequence. 
		-- A simpler value might be `reportDialogueSpeechDur + BUFFER_TIME` if the report logic handles its own timing well.
		-- Using a flag is more robust for initiation.
		
		self.reportInitiated = true
	end
	
	if self.reportingBufferTimeAccum > 0 then
		self.reportingBufferTimeAccum -= deltaTime
	end

	if self.reportingBufferTimeAccum <= 0 then
		agent:getDetectionManager():eraseEntityStatusEntry(agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get():getUuid(), PlayerStatusTypes.MINOR_SUSPICIOUS)
	end
end

function ReportSuspiciousPlayer.getReactionTime(self: ReportSuspiciousPlayer, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

return ReportSuspiciousPlayer