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
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
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
	[MemoryModuleTypes.SPOTTED_TRESPASSER] = MemoryStatus.VALUE_PRESENT
}

function ReportMajorTrespasser.getMemoryRequirements(self: ReportMajorTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReportMajorTrespasser.checkExtraStartConditions(self: ReportMajorTrespasser, agent: Agent): boolean
	return agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
		:filter(function(player)
			local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
			return playerStatusHolder and playerStatusHolder:hasStatus(PlayerStatusTypes.MAJOR_TRESPASSING)
		end)
		:isPresent()
end

function ReportMajorTrespasser.canStillUse(self: ReportMajorTrespasser, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE) and
		agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
			:filter(function(player)
				local detMan = agent:getDetectionManager()
				local detFocus = detMan:getFocusingTarget()
				
				-- Return false if fully detected but NOT major trespassing
				if detFocus and detMan:getDetectionLevel(detFocus.entityUuid) >= 1 then
					return detFocus.status == PlayerStatusTypes.MAJOR_TRESPASSING.name
				end
				
				-- If not fully detected, keep checking (return true)
				return detFocus ~= nil
			end)
			:isPresent()
end

function ReportMajorTrespasser.doStart(self: ReportMajorTrespasser, agent: Agent): ()
	local brain = agent:getBrain()
	local reportCtrl = agent:getReportControl()
	local talkCtrl = agent:getTalkControl()
	local faceCtrl = agent:getFaceControl()

	local trespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER):get()
	local trespasserCurrentArea = Cell.getPlayerOccupiedAreaName(trespasser)
	local reportDialogue

	if trespasserCurrentArea then
		reportDialogue = GuardGenericDialogues["trespassing.major.report.area.known"]
	else
		reportDialogue = GuardGenericDialogues["trespassing.major.report.area.unknown"]
	end

	faceCtrl:setFace("Angry")
	talkCtrl:sayRandomSequences(reportDialogue, trespasserCurrentArea)
	reportCtrl:reportWithCustomDur(ReportType.CRIMINAL_SPOTTED, 2.3)
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