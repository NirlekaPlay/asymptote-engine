--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local Cell = require(ServerScriptService.server.level.cell.Cell)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local DEFAULT_TRESPASSING_UPDATE_TIME = 3

--[=[
	@class ConfrontTrespasser
]=]
local ConfrontTrespasser = {}
ConfrontTrespasser.__index = ConfrontTrespasser
ConfrontTrespasser.ClassName = "ConfrontTrespasser"

export type ConfrontTrespasser = typeof(setmetatable({} :: {
	trespassingUpdateTime: number,
	trespassingCheckTimeAccum: number
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
		trespassingCheckTimeAccum = 0
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
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.SPOTTED_TRESPASSER)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	print("Confronting trespasser - setting angry face")
	
	local brain = agent:getBrain()
	local talkCntrl = agent:getTalkControl()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	local spottedTrespasserPlr = spottedTrespasser:get()
	local speechDurPercentageGain = 10 -- percent
	
	if spottedTrespasser:isPresent() then
		brain:setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, spottedTrespasserPlr)
	end

	agent:getFaceControl():setFace("Angry")

	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(spottedTrespasserPlr)
	local reportDialogue: string
	if trespasserAreaName then
		reportDialogue = `Trespasser in the {trespasserAreaName}.`
	else
		reportDialogue = `I've got a trespasser over here.`
	end

	local reportDialogueSpeechDur = talkCntrl.getStringSpeechDuration(reportDialogue) * (1 + (speechDurPercentageGain / 100))
	talkCntrl:say(reportDialogue, reportDialogueSpeechDur)
	agent:getReportControl():reportOn(ReportType.TRESPASSER_SPOTTED, reportDialogue)
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	agent:getFaceControl():setFace("Neutral")
	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
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

	if not isTrespassing then
		self.trespassingCheckTimeAccum += deltaTime
	else
		self.trespassingCheckTimeAccum = 0
	end

	if self.trespassingCheckTimeAccum >= self.trespassingUpdateTime then
		self.trespassingCheckTimeAccum = 0
		print(trespasserPlayer.Name, "No longer trespassing. Erasing memory.")
		brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)

		local detectionManager = agent:getDetectionManager()

		local entity = EntityManager.getEntityByUuid(tostring(trespasserPlayer.UserId))
		if entity then
			detectionManager:eraseEntityStatusEntry(entity.uuid, PlayerStatusTypes.MINOR_TRESPASSING)
		end
	end
end

--

function ConfrontTrespasser.getReactionTIme(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return 0.7
end

return ConfrontTrespasser