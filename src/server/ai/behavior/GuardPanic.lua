--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local SPEECH_DUR_PERCENTAGE_GAIN = 10

--[=[
	@class GuardPanic
]=]
local GuardPanic = {}
GuardPanic.__index = GuardPanic
GuardPanic.ClassName = "GuardPanic"

export type GuardPanic = typeof(setmetatable({} :: {
}, GuardPanic))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function GuardPanic.new(): GuardPanic
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge
	}, GuardPanic)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID] = MemoryStatus.REGISTERED
}

local ALARMING_STATUSES: { [ PlayerStatus.PlayerStatus ]: true } = {
	[PlayerStatusTypes.ARMED] = true,
	[PlayerStatusTypes.DANGEROUS_ITEM] = true
}

local ALARMING_ENTITY_NAMES: { [string]: true } = {
	["C4"] = true
}

function GuardPanic.getMemoryRequirements(self: GuardPanic): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function GuardPanic.checkExtraStartConditions(self: GuardPanic, agent: Agent): boolean
	local susMan = agent:getDetectionManager()

	-- My god.
	for entityKey, detectionValue in pairs(susMan.detectionLevels) do
		local uuid = string.match(entityKey, "^(.-):") :: string
		local keyStatus = string.match(entityKey, "^.-:(.+)") :: string
		local entityObj = EntityManager.getEntityByUuid(uuid)

		-- On a sidenote, this shit should be tirered based on highest priority
		if entityObj and not entityObj.isStatic and entityObj.name == "Player" then
			local statusObj = PlayerStatusTypes.getStatusFromName(keyStatus)
			if statusObj and ALARMING_STATUSES[statusObj] and detectionValue >= 1 then
				local player = entityObj.instance :: Player
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID, uuid)
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_POSITION, player.Character.PrimaryPart.Position)
				return true
			end
		else
			if entityObj and ALARMING_ENTITY_NAMES[entityObj.name] and detectionValue >= 1 then
				local entityPos: Vector3
				if entityObj.isStatic then
					entityPos = entityObj.position
				else
					local entityInst = entityObj.instance
					if entityInst:IsA("Model") then
						entityPos = entityInst.PrimaryPart.Position
					elseif entityInst:IsA("BasePart") then
						entityPos = entityInst.Position
					end
				end

				if not entityPos then
					warn(uuid, "Does not have a valid way to get position")
					return false
				end

				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID, uuid)
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_POSITION, entityPos)
				return true
			end
		end
	end

	return false
end

function GuardPanic.canStillUse(self: GuardPanic, agent: Agent): boolean
	return true
end

function GuardPanic.doStart(self: GuardPanic, agent: Agent): ()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_PANICKING, true)
	agent:getBrain():eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
	agent:getBodyRotationControl():setRotateTowards(nil)
	local talkCtrl = agent:getTalkControl()
	local reportCtrl = agent:getReportControl()

	local panicSource = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
	local entity = EntityManager.getEntityByUuid(panicSource:get())
	local reportDialogueSeg: {string}
	local reportType: ReportType.ReportType
	local reportDur: number

	-- TODO: intimidation handling
	if entity.name == "C4" then
		reportDur = 2.37
		reportType = ReportType.DANGEROUS_ITEM_SPOTTED
		reportDialogueSeg = GuardGenericDialogues["entity.c4"] :: any
	elseif entity.name == "Player" and not entity.isStatic and entity.instance:IsA("Player") then
		local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(entity.instance)
		if not playerStatusHolder then
			warn("PLAYER_STATUS_HOLDER_NIL", entity.instance)
			return
		end

		local highestStatus = playerStatusHolder:getHighestPriorityStatus()
		if highestStatus == PlayerStatusTypes.ARMED then
			reportDur = 3
			reportType = ReportType.ARMED_PERSON
			reportDialogueSeg = GuardGenericDialogues["status.armed"] :: any
		elseif highestStatus == PlayerStatusTypes.DANGEROUS_ITEM then
			reportDur = 2.3
			reportType = ReportType.PERSON_WITH_DANGEROUS_ITEM
			reportDialogueSeg = GuardGenericDialogues["status.dangerous_item"] :: any
		else
			error("INVALID_CONDITION_1")
		end
	else
		error("INVALID_CONDITION_2")
	end
	agent:getDetectionManager():blockAllDetection()
	task.spawn(function()
		task.wait(0.5) -- TODO: report animation shit, this should be refactored!!!
		if not (agent and agent:isAlive()) then
			return
		end
		talkCtrl:sayRandomSequences(reportDialogueSeg :: any)
	end)
	reportCtrl:reportWithCustomDur(reportType, reportDur)
end

function GuardPanic.doStop(self: GuardPanic, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.IS_PANICKING)
end

function GuardPanic.doUpdate(self: GuardPanic, agent: Agent, deltaTime: number): ()
	return
end

--

function GuardPanic.getReactionTime(self: GuardPanic, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextNumber(0.3, 0.6)
end

return GuardPanic