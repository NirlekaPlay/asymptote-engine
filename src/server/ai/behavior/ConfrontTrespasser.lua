--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AlertLevels = require(ReplicatedStorage.shared.world.stealth.alertlevel.AlertLevels)
local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.world.stealth.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)

local DEFAULT_TRESPASSING_UPDATE_TIME = 3
local WARNING_INTERVAL = 3
local LOST_THRESHOLD = 5 -- Time in seconds before giving up search
local ATTRIBUTE_CONFRONTED_BY = "TrespassingConfrontedBy"

local ConfrontTrespasser = {}
ConfrontTrespasser.__index = ConfrontTrespasser
ConfrontTrespasser.ClassName = "ConfrontTrespasser"

export type ConfrontTrespasser = typeof(setmetatable({} :: {
	timeSinceLastDialogue: number,
	trespassingCheckTimeAccum: number,
	trespassingUpdateTime: number,
	timeSinceLastSeen: number,
	isReportingLost: boolean,
	lastKnownPosition: Vector3?,
	selfDiedConn: RBXScriptConnection?
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
		trespassingUpdateTime = DEFAULT_TRESPASSING_UPDATE_TIME,
		timeSinceLastSeen = 0,
		isReportingLost = false,
		lastKnownPosition = nil :: Vector3?,
		selfDiedConn = nil :: RBXScriptConnection?
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
			local isTrespassing = forStatus == PlayerStatusTypes.MINOR_TRESPASSING
			if not isTrespassing then
				return false
			end

			local entity = EntityManager.getEntityByUuid(priorityEntity:getUuid())
			local player = EntityUtils.getPlayerOrThrow(entity)
			local att = player:GetAttribute(ATTRIBUTE_CONFRONTED_BY)
			local isNotConfrontedByAnotherGuard = att == nil or att == agent:getUuid()

			return isNotConfrontedByAnotherGuard
		end)
		:isPresent()
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		self:checkExtraStartConditions(agent)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	local brain = agent:getBrain()
	local faceControl = agent:getFaceControl()
	local talkControl = agent:getTalkControl()
	local reportContrl = agent:getReportControl()

	self.timeSinceLastDialogue = 0
	self.timeSinceLastSeen = 0
	self.isReportingLost = false

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
	local reportDialogueSpeechDur: number = 0
	local reportRegisterDur = 2.5

	if currentEncounters == 1 then
		doReport = true
		reportType = ReportType.TRESPASSER_SPOTTED
		local trespasserAreaName = agent:getServerLevel():getCellManager():getPlayerOccupiedAreaName(trespasserPlayer)
		reportDialogue = trespasserAreaName and GuardGenericDialogues["trespassing.minor.report.area.known"] or GuardGenericDialogues["trespassing.minor.report.area.unknown"]

		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
		reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
		talkControl:saySequencesWithDelay(choosenDialogue, 0.5, trespasserAreaName)
	elseif currentEncounters == 2 then
		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(GuardGenericDialogues["trespassing.minor.second_encounter"])
		talkControl:saySequences(choosenDialogue)
	elseif currentEncounters >= 3 then
		doReport = true
		reportType = ReportType.CRIMINAL_SPOTTED
		reportDialogue = GuardGenericDialogues["trespassing.minor.non_cooperative"]
		local choosenDialogue = talkControl.randomlyChosoeDialogueSequences(reportDialogue)
		reportDialogueSpeechDur = talkControl.getDialoguesTotalSpeechDuration(choosenDialogue)
		talkControl:saySequencesWithDelay(choosenDialogue, 0.5)
	end

	if doReport and reportType then
		local delayBeforeRadioUnequip = math.max(0, reportDialogueSpeechDur - reportRegisterDur) + 1
		reportContrl:reportWithCustomDur(reportType, reportRegisterDur, delayBeforeRadioUnequip)
		trespasserPlayer:SetAttribute(ATTRIBUTE_CONFRONTED_BY, agent:getUuid())
		agent:getBrain():setMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, trespasserPlayer)
		if not self.selfDiedConn then
			self.selfDiedConn = (agent.character.Humanoid :: Humanoid).Died:Once(function()
				local trespasserMemory = agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
				if trespasserMemory:isPresent() then
					local player = trespasserMemory:get()
					if player:GetAttribute(ATTRIBUTE_CONFRONTED_BY) == agent:getUuid() then
						player:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)
					end
				end
			end)
		end
	end
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.WALK_TARGET)
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
	self.timeSinceLastDialogue = 0

	if not (agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE)
		or agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING)) then
		agent:getFaceControl():setFace("Neutral")
	end

	local trespasserMemory = agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
	if trespasserMemory:isPresent() then
		local player = trespasserMemory:get()
		if player:GetAttribute(ATTRIBUTE_CONFRONTED_BY) == agent:getUuid() then
			player:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)
		end
	end

	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local prioritizedEntity = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local trespasserUuid = prioritizedEntity:getUuid()
	local trespasserEntity = EntityManager.getEntityByUuid(trespasserUuid)
	
	if not trespasserEntity then
		return
	end

	local trespasserPlayer = EntityUtils.getPlayerOrThrow(trespasserEntity)
	local trespasserStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
	local canSee = brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS):map(function(plrs)
		return plrs[trespasserPlayer] ~= nil
	end):isPresent()

	local trespasserHighestStatus = trespasserStatusHolder:getHighestPriorityStatus()
	local isTrespasserTrespassing = trespasserHighestStatus == PlayerStatusTypes.MINOR_TRESPASSING or trespasserHighestStatus == PlayerStatusTypes.MAJOR_TRESPASSING
	local isTalking = agent:getTalkControl():isTalking() or agent:getReportControl():isReporting()

	-- Handle Dialogue Timer
	if isTalking then
		self.timeSinceLastDialogue = 0
	else
		self.timeSinceLastDialogue += deltaTime
	end

	-- Visibility and Movement Logic
	if canSee then
		self.timeSinceLastSeen = 0
		self.lastKnownPosition = trespasserPlayer.Character.HumanoidRootPart.Position
		
		-- Edge Case: Player returned while guard was reporting them lost
		if self.isReportingLost then
			self.isReportingLost = false
			agent:getReportControl():interruptReport()
			agent:getTalkControl():stopTalking()
		end

		local distance = (self.lastKnownPosition - agent:getPrimaryPart().Position).Magnitude
		if isTrespasserTrespassing and distance > 10 then
			brain:setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromPlayer(trespasserPlayer, 1.5, 7))
		end
	else
		self.timeSinceLastSeen += deltaTime
		
		-- Edge Case: Set walk target to last known position once out of sight
		if self.lastKnownPosition and not brain:hasMemoryValue(MemoryModuleTypes.WALK_TARGET) then
			brain:setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromVector3(self.lastKnownPosition, 2, 7))
		end
	end

	-- Logic for giving up and returning to original duties
	if self.timeSinceLastSeen >= LOST_THRESHOLD and not self.isReportingLost then
		self.isReportingLost = true
		local talkControl = agent:getTalkControl()
		local reportControl = agent:getReportControl()
		local lostDialogues
		if Mission.getAlertLevel() == AlertLevels.ALERT then
			lostDialogues = GuardGenericDialogues["trespassing.minor.lost_near_lockdown"]
		else
			lostDialogues = GuardGenericDialogues["trespassing.minor.lost"]
		end
		
		if lostDialogues then
			local chosen = talkControl.randomlyChosoeDialogueSequences(lostDialogues)
			local speechDur = talkControl.getDialoguesTotalSpeechDuration(chosen)
			talkControl:saySequences(chosen)
			reportControl:reportWithCustomDur(ReportType.TRESPASSER_LOST, 2.0, speechDur)
			
			task.delay(speechDur + 0.5, function()
				if self.isReportingLost then
					self:cleanupAndReturn(agent, trespasserUuid)
				end
			end)
		else
			self:cleanupAndReturn(agent, trespasserUuid)
		end
		return
	end

	-- Standard Warning Logic
	if isTrespasserTrespassing and canSee and not isTalking and self.timeSinceLastDialogue >= WARNING_INTERVAL then
		local talkControl = agent:getTalkControl()
		local trespasserWarns = brain:getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):get()
		local currentWarnings = (trespasserWarns[trespasserUuid] or 0) + 1
		trespasserWarns[trespasserUuid] = currentWarnings
		brain:setMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarns)

		local dialogues
		if currentWarnings == 1 then
			dialogues = GuardGenericDialogues["trespassing.minor.warn.1"]
		elseif currentWarnings == 2 then
			dialogues = GuardGenericDialogues["trespassing.minor.warn.2"]
		elseif currentWarnings >= 3 then
			dialogues = GuardGenericDialogues["trespassing.minor.non_cooperative"]
			agent:getReportControl():reportWithCustomDur(ReportType.CRIMINAL_SPOTTED, 2.5, talkControl.getDialoguesTotalSpeechDuration(talkControl.randomlyChosoeDialogueSequences(dialogues)))
		end

		if dialogues then
			talkControl:saySequences(talkControl.randomlyChosoeDialogueSequences(dialogues))
		end
	end

	-- Trespassing Debounce/Check
	if not isTrespasserTrespassing then
		self.trespassingCheckTimeAccum += deltaTime
	else
		self.trespassingCheckTimeAccum = 0
	end

	if self.trespassingCheckTimeAccum >= self.trespassingUpdateTime then
		self:cleanupAndReturn(agent, trespasserUuid)
	end
end

function ConfrontTrespasser.cleanupAndReturn(self: ConfrontTrespasser, agent: Agent, uuid: string)
	local brain = agent:getBrain()
	local player = EntityUtils.getPlayerOrThrow(EntityManager.getEntityByUuid(uuid))
	player:SetAttribute(ATTRIBUTE_CONFRONTED_BY, nil)
	
	brain:eraseMemory(MemoryModuleTypes.WALK_TARGET)
	brain:eraseMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
	agent:getDetectionManager():eraseEntityStatusEntry(uuid, PlayerStatusTypes.MINOR_TRESPASSING)
	
	self.isReportingLost = false
	self.timeSinceLastSeen = 0
	self.lastKnownPosition = nil
end

function ConfrontTrespasser.getReactionTime(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(1, 1.5)
end

return ConfrontTrespasser