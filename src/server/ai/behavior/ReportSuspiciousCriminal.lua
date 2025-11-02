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
local Cell = require(ServerScriptService.server.world.level.cell.Cell)

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
	[MemoryModuleTypes.SPOTTED_CRIMINAL] = MemoryStatus.REGISTERED
}

function ReportSuspiciousCriminal.getMemoryRequirements(self: ReportSuspiciousCriminal): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportSuspiciousCriminal.checkExtraStartConditions(self: ReportSuspiciousCriminal, agent: Agent): boolean
	local detetectionManager = agent:getDetectionManager()
	local focusingTarget = detetectionManager:getHighestFullyDetectedEntity()
	if focusingTarget then
		if focusingTarget.status ~= PlayerStatusTypes.CRIMINAL_SUSPICIOUS.name then
			return false
		end
		return true
	end

	return false
end

function ReportSuspiciousCriminal.canStillUse(self: ReportSuspiciousCriminal, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING) and
		agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_CRIMINAL)
			:filter(function(player)
				local detMan = agent:getDetectionManager()
				local detFocus = detMan:getHighestFullyDetectedEntity()
				
				-- Only continue if we're still focusing on THE SAME PLAYER
				-- Don't care what status they have, just that it's still them
				if not detFocus then
					return false
				end
				
				local playerUuid = tostring(player.UserId)
				return detFocus.entityUuid == playerUuid
			end)
			:isPresent()
end

function ReportSuspiciousCriminal.doStart(self: ReportSuspiciousCriminal, agent: Agent): ()
	local brain = agent:getBrain()
	local reportCtrl = agent:getReportControl()
	local talkCtrl = agent:getTalkControl()
	local faceCtrl = agent:getFaceControl()

	local criminal = ((EntityManager.getEntityByUuid((agent:getDetectionManager():getHighestFullyDetectedEntity() :: any).entityUuid) :: any).instance)
	brain:setNullableMemory(MemoryModuleTypes.SPOTTED_CRIMINAL, criminal)
	local criminalCurrentArea = Cell.getPlayerOccupiedAreaName(criminal)
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
end

function ReportSuspiciousCriminal.doStop(self: ReportSuspiciousCriminal, agent: Agent): ()
	agent:getReportControl():interruptReport()
	agent:getTalkControl():stopTalking()
end

function ReportSuspiciousCriminal.doUpdate(self: ReportSuspiciousCriminal, agent: Agent, deltaTime: number): ()
	return
end

function ReportSuspiciousCriminal.getReactionTime(self: ReportSuspiciousCriminal, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextInteger(0.7, 1)
end

return ReportSuspiciousCriminal