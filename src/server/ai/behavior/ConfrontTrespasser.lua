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
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local DEFAULT_TRESPASSING_UPDATE_TIME = 3
local WARNING_INTERVAL = 2 -- seconds between warnings
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
	warningLevel: number,
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
		warningLevel = 0,
		timeSinceLastDialogue = 0,
		currentlySpeaking = false,
		currentSpeechDuration = 0
	}, ConfrontTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.SPOTTED_TRESPASSER] = MemoryStatus.VALUE_PRESENT
}

function ConfrontTrespasser.getMemoryRequirements(self: ConfrontTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ConfrontTrespasser.checkExtraStartConditions(self: ConfrontTrespasser, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
		:filter(function(player)
			local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
			return playerStatusHolder and playerStatusHolder:hasStatus(PlayerStatusTypes.MINOR_TRESPASSING)
		end)
		:isPresent()
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
			:filter(function(player)
				local detMan = agent:getDetectionManager()
				local detFocus = detMan:getHighestFullyDetectedEntity()
				
				-- Return false if fully detected but NOT minor trespassing
				if detFocus and detMan:getDetectionLevel(detFocus.entityUuid) >= 1 then
					return detFocus.status == PlayerStatusTypes.MINOR_TRESPASSING.name
				end
				
				-- If not fully detected, keep checking (return true)
				return detFocus ~= nil
			end)
			:isPresent()
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	
	local brain = agent:getBrain()
	local talkCntrl = agent:getTalkControl()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	local spottedTrespasserPlr = spottedTrespasser:get()
	local beingConfrontedBy = spottedTrespasserPlr:GetAttribute(ATTRIBUTE_CONFRONTED_BY) :: string?

	if beingConfrontedBy ~= nil then
		agent:getFaceControl():setFace("Angry")
		return
	else
		spottedTrespasserPlr:SetAttribute(ATTRIBUTE_CONFRONTED_BY, agent:getUuid())
	end
	
	if spottedTrespasser:isPresent() then
		brain:setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, spottedTrespasserPlr)
	end

	agent:getFaceControl():setFace("Angry")
	
	brain:setNullableMemory(MemoryModuleTypes.FOLLOW_TARGET, spottedTrespasserPlr)

	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(spottedTrespasserPlr)
	local reportDialogue: {{string}}
	if trespasserAreaName then
		reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.known"] :: any
	else
		reportDialogue = GuardGenericDialogues["trespassing.minor.report.area.unknown"] :: any
	end
	local choosenDialogue = talkCntrl.randomlyChosoeDialogueSequences(reportDialogue)

	local reportDialogueSpeechDur = talkCntrl.getDialoguesTotalSpeechDuration(choosenDialogue)
	task.spawn(function()
		task.wait(0.5) -- TODO: report animation shit, this should be refactored!!!
		if not self:canStillUse(agent) then
			return
		end
		talkCntrl:saySequences(choosenDialogue, trespasserAreaName)
	end)
	agent:getReportControl():reportWithCustomDur(ReportType.TRESPASSER_SPOTTED, 2.5)
	
	-- Track speeches
	-- TODO: Probably use memory instead
	self.currentlySpeaking = true
	self.currentSpeechDuration = reportDialogueSpeechDur
	self.warningLevel = 0
	self.timeSinceLastDialogue = 0
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	agent:getFaceControl():setFace("Neutral")
	agent:getNavigation():setToWalkingSpeed()
	agent:getBrain():eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()

	local brain = agent:getBrain()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	if spottedTrespasser:isPresent() then
		local trespasserPlayer = spottedTrespasser:get()
		trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)
		local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
		if not statusHolder or not statusHolder:hasStatus(PlayerStatusTypes.MINOR_TRESPASSING) then
			print(trespasserPlayer.Name, "No longer trespassing (cleaning up in doStop).")
			brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
			trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)
			local detectionManager = agent:getDetectionManager()
			local entity = EntityManager.getEntityByUuid(tostring(trespasserPlayer.UserId))
			if entity then
				detectionManager:eraseEntityStatusEntry(entity.uuid, PlayerStatusTypes.MINOR_TRESPASSING)
			end
		end
	end

	self.warningLevel = 0
	self.timeSinceLastDialogue = 0
	self.currentlySpeaking = false
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	if spottedTrespasser:isEmpty() then
		return
	end

	local trespasserPlayer = spottedTrespasser:get()
	local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
	if not statusHolder then
		warn("STATUS_HOLDER_NIL: " .. trespasserPlayer.Name)
		return
	end

	local isTrespassing = statusHolder:hasStatus(PlayerStatusTypes.MINOR_TRESPASSING)

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
		print(trespasserPlayer.Name, "No longer trespassing. Erasing memory.")
		brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
		trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)

		local detectionManager = agent:getDetectionManager()
		local entity = EntityManager.getEntityByUuid(tostring(trespasserPlayer.UserId))
		if entity then
			detectionManager:eraseEntityStatusEntry(entity.uuid, PlayerStatusTypes.MINOR_TRESPASSING)
		end
	end
end

function ConfrontTrespasser.escalateWarning(self: ConfrontTrespasser, agent: Agent): ()
	-- TODO: Add warnings between trespassing encounters
	local talkCntrl = agent:getTalkControl()
	
	self.warningLevel += 1
	
	local dialogue: {string}
	local speechDur: number

	if self.warningLevel == 1 then
		dialogue = talkCntrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["trespassing.minor.warn.1"] :: any)
	elseif self.warningLevel == 2 then
		dialogue = talkCntrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["trespassing.minor.warn.2"] :: any)
	elseif self.warningLevel == 3 then
		dialogue = talkCntrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["trespassing.minor.non_cooperative"] :: any)
		speechDur = talkCntrl.getDialoguesTotalSpeechDuration(dialogue)
		agent:getReportControl():reportWithCustomDur(ReportType.CRIMINAL_SPOTTED, 2, speechDur)
	else
		-- Already at max warning level, don't say anything more
		return
	end
	
	talkCntrl:saySequences(dialogue)

	self.currentlySpeaking = true
	self.currentSpeechDuration = speechDur or talkCntrl.getDialoguesTotalSpeechDuration(dialogue)
	self.timeSinceLastDialogue = 0
	
	print(`Warning level {self.warningLevel}: "{dialogue}"`)
end

--

function ConfrontTrespasser.getReactionTime(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(0.7, 1)
end

return ConfrontTrespasser