--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local TalkingAgent = require(ServerScriptService.server.TalkingAgent)
local Attributes = require(ServerScriptService.server.ai.attributes.Attributes)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local MAX_WARNS = 3

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
type Agent = Agent.Agent & TalkingAgent.TalkingAgent & ArmedAgent.ArmedAgent

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
	local trespasser = susMan.detectedStatuses["MINOR_TRESPASSING"]

	if not trespasser then
		return
	end

	agent:getFaceControl():setFace("Angry")
	local speechDurPercentageGain = 10 -- percent
	local reportDialogue = "Trespasser in the north office."
	local reportDialogueSpeechDur = talkCntrl.getStringSpeechDuration(reportDialogue) * (1 + (speechDurPercentageGain / 100))
	talkCntrl:say(reportDialogue, reportDialogueSpeechDur)
	agent:getBrain():setMemoryWithExpiry(MemoryModuleTypes.REPORTING_ON, { reportType = "MINOR_TRESPASSER" }, reportDialogueSpeechDur)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, trespasser)
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	if not agent:getBrain():hasMemoryValue(MemoryModuleTypes.KILL_TARGET) then
		agent:getFaceControl():setFace("Neutral")
	end
	agent:getBrain():eraseMemory(MemoryModuleTypes.REPORTING_ON)
	agent:getBrain():eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local reportingOn = agent:getBrain():getMemory(MemoryModuleTypes.REPORTING_ON):flatMap(function(expVal)
		return expVal:getValue()
	end)

	if reportingOn and reportingOn.reportType == "MINOR_TRESPASSER" then
		return
	end

	local trespasser = agent:getBrain():getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER):flatMap(function(expValue)
		return expValue:getValue()
	end)

	local trespasserWarnsMemory = agent:getBrain():getMemory(MemoryModuleTypes.TRESPASSERS_WARNS):map(function(expValue)
		return expValue:getValue()
	end)
		:orElse({})

	local playerStatuses = PlayerStatusRegistry.getPlayerStatuses(trespasser)
	local highestStatus = playerStatuses:getHighestPriorityStatus()
	if (agent:getSuspicionManager().detectedStatuses[highestStatus] and highestStatus ~= "MINOR_TRESPASSING") then
		warn("aborting confrontation to higher priority status")
		agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
	elseif playerStatuses.currentStatusesMap["MINOR_TRESPASSING"] == nil then
		warn("player is no longer trespassing")
		agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
		agent:getSuspicionManager().detectedStatuses["MINOR_TRESPASSING"] = nil
		if agent:getSuspicionManager().suspicionLevels[trespasser]["MINOR_TRESPASSING"] >= 1 then
			agent:getSuspicionManager().suspicionLevels[trespasser]["MINOR_TRESPASSING"] = nil
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

return ConfrontTrespasser