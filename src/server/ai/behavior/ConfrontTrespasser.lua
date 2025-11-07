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
	trespassingUpdateTime: number,
	trespassingCheckTimeAccum: number,
	timeSinceLastDialogue: number,
	currentlySpeaking: boolean,
	currentSpeechDuration: number
}, ConfrontTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent & DetectionAgent.DetectionAgent

function ConfrontTrespasser.new(): ConfrontTrespasser
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
		--
		trespassingUpdateTime = DEFAULT_TRESPASSING_UPDATE_TIME,
		trespassingCheckTimeAccum = 0,
		timeSinceLastDialogue = 0,
		currentlySpeaking = false,
		currentSpeechDuration = 0
	}, ConfrontTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TRESPASSERS_WARNS] = MemoryStatus.REGISTERED
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
		self:checkExtraStartConditions(agent) and
		agent:getBrain():hasMemoryValue(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	local brain = agent:getBrain()
	local faceControl = agent:getFaceControl()
	local talkControl = agent:getTalkControl()
	local reportContrl = agent:getReportControl()

	local trespasserWarns = brain:getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):orElse({})
	local detectedTrespasser = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local trespasserUuid = detectedTrespasser:getUuid()
	local trespasserEntity = EntityManager.getEntityByUuid(trespasserUuid)
	local trespasserPlayer = EntityUtils.getPlayerOrThrow(trespasserEntity)
	local currentWarnings = trespasserWarns[trespasserUuid] or 0

	trespasserWarns[trespasserUuid] = currentWarnings

	brain:setMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarns)
	brain:setMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, trespasserPlayer)
	faceControl:setFace("Angry")

	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(trespasserPlayer)
	local reportDialogue
	if trespasserAreaName then
		reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.known"]
	else
		reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.unknown"]
	end

	local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
	local reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
	task.spawn(function()
		task.wait(0.5) -- TODO: report animation shit, this should be refactored!!!
		if not self:canStillUse(agent) then
			return
		end
		talkControl:saySequences(choosenDialogue, trespasserAreaName)

		-- Track speeches
		-- TODO: Probably use memory instead
		self.currentlySpeaking = true
		self.currentSpeechDuration = reportDialogueSpeechDur
		self.timeSinceLastDialogue = 0
	end)

	local reportRegisterDur = 2.5
	local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
	reportContrl:reportWithCustomDur(
		ReportType.TRESPASSER_SPOTTED,
		reportRegisterDur,
		delayBeforeRadioUnequip
	)
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	print("Stop")
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	-- TODO: Handle stuff when the trespasser leaves the game

	local brain = agent:getBrain()
	local trespasserPlayer = brain:getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER):get()
	local trespasserStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
	local isTrespassing = trespasserStatusHolder:getHighestPriorityStatus() == PlayerStatusTypes.MINOR_TRESPASSING

	-- Update speech timer
	if self.currentlySpeaking then
		self.currentSpeechDuration -= deltaTime
		if self.currentSpeechDuration <= 0 then
			self.currentlySpeaking = false
		end
	end

	-- Update dialogue timer
	if not self.currentlySpeaking then
		self.timeSinceLastDialogue += deltaTime
	end

	-- Escalate warnings
	if isTrespassing and not self.currentlySpeaking and self.timeSinceLastDialogue >= WARNING_INTERVAL then
		self.timeSinceLastDialogue = 0
		self:escalateWarning(agent)
	end

	-- Check if player stopped trespassing (debounce logic)
	if not isTrespassing then
		self.trespassingCheckTimeAccum += deltaTime
	else
		self.trespassingCheckTimeAccum = 0
	end

	if self.trespassingCheckTimeAccum >= self.trespassingUpdateTime then
		self.trespassingCheckTimeAccum = 0
		print(trespasserPlayer.Name, "is no longer trespassing. Erasing memory.")
		brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
		trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)

		local detectionManager = agent:getDetectionManager()
		local entity = EntityManager.getEntityByUuid(tostring(trespasserPlayer.UserId))
		if entity then
			detectionManager:eraseEntityStatusEntry(entity.uuid, PlayerStatusTypes.MINOR_TRESPASSING)
		end
	end
end

--

function ConfrontTrespasser.escalateWarning(self: ConfrontTrespasser, agent: Agent): ()
	if self.currentlySpeaking then
		return
	end  -- block escalation while speaking

	self.currentlySpeaking = true  -- mark as speaking BEFORE starting dialogue
	self.timeSinceLastDialogue = 0
	-- TODO: Add warnings between trespassing encounters
	local talkCntrl = agent:getTalkControl()

	local trespasser = agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER):get()
	local trespasserWarnsMemory = agent:getBrain():getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):orElse({}) :: any
	local key = tostring(trespasser.UserId)
	trespasserWarnsMemory[key] += 1
	local trespasserWarns = trespasserWarnsMemory[key]

	agent:getBrain():setMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarnsMemory)
	
	local dialogue
	local doReport = false

	if trespasserWarns == 1 then
		dialogue = GuardGenericDialogues["trespassing.minor.warn.1"]
	elseif trespasserWarns == 2 then
		dialogue = GuardGenericDialogues["trespassing.minor.warn.2"]
	elseif trespasserWarns == 3 then
		dialogue = GuardGenericDialogues["trespassing.minor.non_cooperative"]
		doReport = true
	else
		-- Already at max warning level, don't say anything more
		return
	end

	local choosenDialogue = talkCntrl.randomlyChosoeDialogueSequences(dialogue)
	local speechDur = talkCntrl.getDialoguesTotalSpeechDuration(choosenDialogue)
	talkCntrl:saySequences(choosenDialogue)
	if doReport then
		local reportRegisterDur = 2
		local delayBeforeRadioUnequip = math.max(0, speechDur - reportRegisterDur) + 1
		agent:getReportControl():reportWithCustomDur(
			ReportType.CRIMINAL_SPOTTED,
			reportRegisterDur,
			delayBeforeRadioUnequip
		)
	end

	self.currentlySpeaking = true
	self.currentSpeechDuration = speechDur
	self.timeSinceLastDialogue = 0
end

--

function ConfrontTrespasser.getReactionTime(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(0.7, 1)
end

return ConfrontTrespasser