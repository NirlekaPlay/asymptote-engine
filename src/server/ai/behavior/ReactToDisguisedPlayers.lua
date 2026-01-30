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
	@class ReactToDisguisedPlayers
]=]
local ReactToDisguisedPlayers = {}
ReactToDisguisedPlayers.__index = ReactToDisguisedPlayers
ReactToDisguisedPlayers.ClassName = "ReactToDisguisedPlayers"

export type ReactToDisguisedPlayers = typeof(setmetatable({} :: {
}, ReactToDisguisedPlayers))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReactToDisguisedPlayers.new(): ReactToDisguisedPlayers
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ReactToDisguisedPlayers)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED
}

function ReactToDisguisedPlayers.getMemoryRequirements(self: ReactToDisguisedPlayers): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReactToDisguisedPlayers.checkExtraStartConditions(self: ReactToDisguisedPlayers, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local forStatus = PlayerStatusTypes.getStatusFromName(priorityEntity:getStatus())

			return forStatus == PlayerStatusTypes.DISGUISED
		end)
		:isPresent()
end

function ReactToDisguisedPlayers.canStillUse(self: ReactToDisguisedPlayers, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		self:checkExtraStartConditions(agent)
end

function ReactToDisguisedPlayers.doStart(self: ReactToDisguisedPlayers, agent: Agent): ()
	local talkCtrl = agent:getTalkControl()
	local reportCtrl = agent:getReportControl()
	local faceCtrl = agent:getFaceControl()

	local disguisedPrioEntity = agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local player = EntityUtils.getPlayerOrThrow(EntityManager.getEntityByUuid(disguisedPrioEntity:getUuid()))
	local playerDisguiseClass = (player.Character :: Model):GetAttribute("CurrentDisguiseClass") :: number

	local reportDialogue
	if playerDisguiseClass == 0 then
		reportDialogue = talkCtrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["status.disguised"])
	elseif playerDisguiseClass == 1 then
		reportDialogue = talkCtrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["status.disguised.employee"])
	else
		error("ERR_INVALID_DISGUISE_CLASS")
	end
	local reportDialogueTotalDur = talkCtrl.getDialoguesTotalSpeechDuration(reportDialogue)

	faceCtrl:setFace("Angry")
	talkCtrl:saySequencesWithDelay(reportDialogue, 0.5)
	reportCtrl:reportWithCustomDur(ReportType.INTRUDER_SPOTTED, 2, reportDialogueTotalDur)

	local disguisedUuid = agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get():getUuid()
	local disguisedPlayer = EntityUtils.getPlayerOrThrow(EntityManager.getEntityByUuid(disguisedUuid))
	local targetableEntitiesMemory = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES):orElse({})
	targetableEntitiesMemory[disguisedPlayer] = true
	agent:getBrain():setMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntitiesMemory)
end

function ReactToDisguisedPlayers.doStop(self: ReactToDisguisedPlayers, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
end

function ReactToDisguisedPlayers.doUpdate(self: ReactToDisguisedPlayers, agent: Agent, deltaTime: number): ()
	return
end

--

function ReactToDisguisedPlayers.getReactionTime(self: ReactToDisguisedPlayers, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextNumber(0.5, 0.7)
end

return ReactToDisguisedPlayers