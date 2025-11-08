--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local DEFAULT_TRESPASSING_UPDATE_TIME = 3
local WARNING_INTERVAL = 3 -- seconds between warnings
local ATTRIBUTE_CONFRONTED_BY = "TrespassingConfrontedBy"

--[=[
	@class ConfrontTrespasser
]=]
local ConfrontTrespasser = {}
ConfrontTrespasser.__index = ConfrontTrespasser
ConfrontTrespasser.ClassName = "ConfrontTrespasser"

export type ConfrontTrespasser = typeof(setmetatable({} :: {
	timeSinceLastDialogue: number,
	trespassingCheckTimeAccum: number,
	trespassingUpdateTime: number
}, ConfrontTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent & DetectionAgent.DetectionAgent

function ConfrontTrespasser.new(): ConfrontTrespasser
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
		timeSinceLastDialogue = 0,
		trespassingCheckTimeAccum = 0,
		trespassingUpdateTime = DEFAULT_TRESPASSING_UPDATE_TIME
	}, ConfrontTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TRESPASSERS_WARNS] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.TRESPASSERS_ENCOUNTERS] = MemoryStatus.REGISTERED
}

function ConfrontTrespasser.getMemoryRequirements(self: ConfrontTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ConfrontTrespasser.checkExtraStartConditions(self: ConfrontTrespasser, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local forStatus = PlayerStatusTypes.getStatusFromName(priorityEntity:getStatus())

			return forStatus == PlayerStatusTypes.MINOR_TRESPASSING
		end)
		:isPresent()
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		self:checkExtraStartConditions(agent)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	print("Called")
	local brain = agent:getBrain()
	local faceControl = agent:getFaceControl()
	local talkControl = agent:getTalkControl()
	local reportContrl = agent:getReportControl()

	self.timeSinceLastDialogue = 0

	local trespasserWarns = brain:getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):orElse({})
	local trespasserEncounters = brain:getMemory(MemoryModuleTypes.TRESPASSERS_ENCOUNTERS):orElse({})
	local detectedTrespasser = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local trespasserUuid = detectedTrespasser:getUuid()
	local trespasserEntity = EntityManager.getEntityByUuid(trespasserUuid)
	local trespasserPlayer = EntityUtils.getPlayerOrThrow(trespasserEntity)
	local currentWarnings = trespasserWarns[trespasserUuid] or 0
	local currentEncounters = (trespasserEncounters[trespasserUuid] or 0) :: number + 1

	trespasserWarns[trespasserUuid] = currentWarnings
	trespasserEncounters[trespasserUuid] = currentEncounters

	brain:setMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarns)
	brain:setMemory(MemoryModuleTypes.TRESPASSERS_ENCOUNTERS, trespasserEncounters)
	faceControl:setFace("Angry")

	local doReport = false
	local reportType
	local reportDialogue
	local reportDialogueSpeechDur: number
	local reportRegisterDur = 2.5

	if currentEncounters == 1 then
		doReport = true
		reportType = ReportType.TRESPASSER_SPOTTED
		local trespasserAreaName = Cell.getPlayerOccupiedAreaName(trespasserPlayer)
		
		if trespasserAreaName then
			reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.known"]
		else
			reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.unknown"]
		end

		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
		reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
		talkControl:saySequencesWithDelay(choosenDialogue, 0.5, trespasserAreaName)
	elseif currentEncounters == 2 then
		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(GuardGenericDialogues["trespassing.minor.second_encounter"])
		talkControl:saySequences(choosenDialogue)
	elseif currentEncounters == 3 then
		doReport = true
		reportType = ReportType.CRIMINAL_SPOTTED
		reportDialogue = GuardGenericDialogues["trespassing.minor.non_cooperative"]
		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
		reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
		talkControl:saySequencesWithDelay(choosenDialogue, 0.5)
	end

	if doReport and reportType then
		local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
		reportContrl:reportWithCustomDur(
			reportType,
			reportRegisterDur,
			delayBeforeRadioUnequip
		)
	end
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()

	self.timeSinceLastDialogue = 0
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local trespasserUuid = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get():getUuid()
	local trespasserPlayer = EntityUtils.getPlayerOrThrow(EntityManager.getEntityByUuid(trespasserUuid))
	local trespasserStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
	local isTrespasserTrespassing = trespasserStatusHolder:getHighestPriorityStatus() == PlayerStatusTypes.MINOR_TRESPASSING -- to be or not to be?
	local isTalking = agent:getTalkControl():isTalking() or agent:getReportControl():isReporting()

	-- TODO: Handle circumstances where player cannot be confronted when not in view
	-- for example, stop chasing and report it.

	if isTalking then
		self.timeSinceLastDialogue = 0
	else
		self.timeSinceLastDialogue += deltaTime
	end

	if isTrespasserTrespassing and not isTalking and self.timeSinceLastDialogue >= WARNING_INTERVAL then
		local talkControl = agent:getTalkControl()
		local trespasserWarns = brain:getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):get()
		local trespasserEncounters = brain:getMemory(MemoryModuleTypes.TRESPASSERS_ENCOUNTERS):get()
		local currentWarnings = trespasserWarns[trespasserUuid] + 1
		local currentEncounters = trespasserEncounters[trespasserUuid]

		trespasserWarns[trespasserUuid] = currentWarnings

		brain:setMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarns)

		local doReport = false
		local reportDur = 0
		local reportType: ReportType.ReportType
		local dialogues: any

		print("For", trespasserPlayer ,"Current warnings:", currentWarnings, "Current encounters:", currentEncounters)

		if currentWarnings == 1 and currentEncounters == 2 then
			dialogues = GuardGenericDialogues["trespassing.minor.warn.2.second_encounter"]
		elseif currentWarnings == 1 then
			dialogues = GuardGenericDialogues["trespassing.minor.warn.1"]
		elseif currentWarnings == 2 then
			dialogues = GuardGenericDialogues["trespassing.minor.warn.2"]
		elseif currentWarnings >= 3 then
			doReport = true
			reportDur = 2.5
			reportType = ReportType.CRIMINAL_SPOTTED
			dialogues = GuardGenericDialogues["trespassing.minor.non_cooperative"]
		end

		if dialogues then
			local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(dialogues)
			talkControl:saySequencesWithDelay(choosenDialogue, (doReport and reportDur) and 0.5 or 0)
			if doReport and reportType then
				agent:getReportControl():reportWithCustomDur(
					reportType,
					reportDur,
					talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
				)
			end
		end
	end

	-- Check if player stopped trespassing (debounce logic)
	if not isTrespasserTrespassing then
		self.trespassingCheckTimeAccum += deltaTime
	else
		self.trespassingCheckTimeAccum = 0
	end

	if self.trespassingCheckTimeAccum >= self.trespassingUpdateTime then
		self.trespassingCheckTimeAccum = 0
		print(trespasserPlayer.Name, "No longer trespassing. Erasing memory.")
		brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
		trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)

		local detectionManager = agent:getDetectionManager()
		detectionManager:eraseEntityStatusEntry(trespasserUuid, PlayerStatusTypes.MINOR_TRESPASSING)
	end
end

--

function ConfrontTrespasser.getReactionTime(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

return ConfrontTrespasser