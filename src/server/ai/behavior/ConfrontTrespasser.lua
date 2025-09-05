--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local TalkingAgent = require(ServerScriptService.server.TalkingAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Cell = require(ServerScriptService.server.cell.Cell)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class ConfrontTrespasser
]=]
local ConfrontTrespasser = {}
ConfrontTrespasser.__index = ConfrontTrespasser
ConfrontTrespasser.ClassName = "ConfrontTrespasser"

export type ConfrontTrespasser = typeof(setmetatable({} :: {
	patienceCooldown: number
}, ConfrontTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & TalkingAgent.TalkingAgent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent

function ConfrontTrespasser.new(): ConfrontTrespasser
	return setmetatable({
		minDuration = 1000,
		maxDuration = 1000,
		--
		patienceCooldown = 0
	}, ConfrontTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.SPOTTED_TRESPASSER] = MemoryStatus.VALUE_PRESENT
}

function ConfrontTrespasser.getMemoryRequirements(self: ConfrontTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ConfrontTrespasser.checkExtraStartConditions(self: ConfrontTrespasser, agent: Agent): boolean
	return true
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return (not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING)) 
		and agent:getBrain():hasMemoryValue(MemoryModuleTypes.CONFRONTING_TRESPASSER)
		and not agent:getBrain():hasMemoryValue(MemoryModuleTypes.KILL_TARGET)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	local susMan = agent:getSuspicionManager()
	local talkCntrl = agent:getTalkControl()
	local trespasser = susMan.detectedStatuses[PlayerStatusTypes.MINOR_TRESPASSING] :: Player

	if not trespasser then
		return
	end

	agent:getFaceControl():setFace("Angry")
	local speechDurPercentageGain = 10 -- percent
	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(trespasser)
	local reportDialogue: string
	if trespasserAreaName then
		reportDialogue = `Trespasser in the {trespasserAreaName}.`
	else
		reportDialogue = `I've got a trespasser over here.`
	end
	local reportDialogueSpeechDur = talkCntrl.getStringSpeechDuration(reportDialogue) * (1 + (speechDurPercentageGain / 100))
	talkCntrl:say(reportDialogue, reportDialogueSpeechDur)
	agent:getReportControl():reportOn(ReportType.TRESPASSER_SPOTTED, reportDialogue)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.LOOK_TARGET, trespasser)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, trespasser)
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	if not agent:getBrain():hasMemoryValue(MemoryModuleTypes.KILL_TARGET) then
		agent:getFaceControl():setFace("Neutral")
	end
	agent:getReportControl():interruptReport()
	agent:getBrain():eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
	agent:getBrain():eraseMemory(MemoryModuleTypes.REPORTING_ON)
	agent:getBrain():eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	if agent:getReportControl():isReporting() then
		return
	end

	local trespasser = agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER):orElse(nil)
	if not trespasser then
		warn("Trespasser is nil!")
		return
	end

	local trespasserWarnsMemory = agent:getBrain():getMemory(MemoryModuleTypes.TRESPASSERS_WARNS)
		:orElse({})

	local playerStatuses = PlayerStatusRegistry.getPlayerStatusHolder(trespasser)
	local highestStatus = playerStatuses:getHighestPriorityStatus()
	if highestStatus == PlayerStatusTypes.MAJOR_TRESPASSING then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, trespasser)
		return
	end

	if (agent:getSuspicionManager().detectedStatuses[highestStatus] and highestStatus ~= PlayerStatusTypes.MINOR_TRESPASSING) then
		warn("aborting confrontation to higher priority status")
		agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
	elseif playerStatuses.currentStatusesMap[PlayerStatusTypes.MINOR_TRESPASSING] == nil then
		warn("player is no longer trespassing")
		agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
		agent:getSuspicionManager().detectedStatuses[PlayerStatusTypes.MINOR_TRESPASSING] = nil
		if agent:getSuspicionManager().suspicionLevels[trespasser][PlayerStatusTypes.MINOR_TRESPASSING] >= 1 then
			agent:getSuspicionManager().suspicionLevels[trespasser][PlayerStatusTypes.MINOR_TRESPASSING] = nil
		end
	end

	if trespasserWarnsMemory[trespasser] == nil or trespasserWarnsMemory[trespasser] <= 0 then
		agent:getTalkControl():say("This area is restricted. You need to leave.")
		trespasserWarnsMemory[trespasser] = trespasserWarnsMemory[trespasser] or 0
		trespasserWarnsMemory[trespasser] += 1
	end

	if not agent:getTalkControl():isTalking() then
		self.patienceCooldown += deltaTime
	end

	if self.patienceCooldown >= 2 then
		self.patienceCooldown = 0
		trespasserWarnsMemory[trespasser] += 1
		if trespasserWarnsMemory[trespasser] == 2 then
			agent:getBrain():setNullableMemory(MemoryModuleTypes.FOLLOW_TARGET, trespasser)
			agent:getTalkControl():saySequences({"I'm not going to warn you again.", "You need to leave now."})
		elseif trespasserWarnsMemory[trespasser] == 3 then
			agent:getBrain():eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
			agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, trespasser)
			agent:getTalkControl():say("Alright! You were warned!")
		end
	end

	agent:getBrain():setNullableMemory(MemoryModuleTypes.TRESPASSERS_WARNS, trespasserWarnsMemory)
end

--

function ConfrontTrespasser.getReactionTIme(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return 0.7
end

return ConfrontTrespasser