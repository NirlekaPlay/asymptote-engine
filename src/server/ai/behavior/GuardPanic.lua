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
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)

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
	[MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PANIC_POSITION] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.FOLLOW_TARGET] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_PRESENT
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
	return agent:getBrain():getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY)
		:filter(function(priorityEntity)
			local entityUuid = priorityEntity:getUuid()
			local forStatus = priorityEntity:getStatus()
			local entityObj = EntityManager.getEntityByUuid(entityUuid)

			if EntityUtils.isPlayer(entityObj) then
				local statusObj = PlayerStatusTypes.getStatusFromName(forStatus)
				if statusObj and ALARMING_STATUSES[statusObj] then
					return true
				end
			else
				if entityObj and ALARMING_ENTITY_NAMES[entityObj.name] then
					return true
				end
			end

			return false
		end)
		:isPresent()
end

function GuardPanic.canStillUse(self: GuardPanic, agent: Agent): boolean
	return true
end

function GuardPanic.doStart(self: GuardPanic, agent: Agent): ()
	local brain = agent:getBrain()
	local talkCtrl = agent:getTalkControl()
	local reportCtrl = agent:getReportControl()
	local panicSource = brain:getMemory(MemoryModuleTypes.PRIORITIZED_ENTITY):get()
	local entity = EntityManager.getEntityByUuid(panicSource:getUuid())

	brain:setMemory(MemoryModuleTypes.IS_PANICKING, true)
	brain:eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
	brain:setMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID, panicSource:getUuid())
	brain:setMemory(MemoryModuleTypes.PANIC_POSITION, EntityUtils.getPos(entity))
	agent:getBodyRotationControl():setRotateTowards(nil)

	local reportDialogueSeg: {string}
	local reportType: ReportType.ReportType
	local reportDur: number

	-- TODO: intimidation handling
	if entity.name == "C4" then
		reportDur = 2.37
		reportType = ReportType.DANGEROUS_ITEM_SPOTTED
		reportDialogueSeg = GuardGenericDialogues["entity.c4"] :: any
	elseif EntityUtils.isPlayer(entity) then
		-- Avoid retrieving from the player status holder directly,
		-- we need to know what the NPC SAW instead of the current status
		-- the Player has in this frame. This is also to avoid other race issues.
		local status = PlayerStatusTypes.getStatusFromName(panicSource:getStatus())
		if status == PlayerStatusTypes.ARMED then
			reportDur = 3
			reportType = ReportType.ARMED_PERSON
			reportDialogueSeg = GuardGenericDialogues["status.armed"] :: any
		elseif status == PlayerStatusTypes.DANGEROUS_ITEM then
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
	agent:getNavigation():setToWalkingSpeed()
end

function GuardPanic.doUpdate(self: GuardPanic, agent: Agent, deltaTime: number): ()
	return
end

--

function GuardPanic.getReactionTime(self: GuardPanic, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextNumber(0.3, 0.6)
end

return GuardPanic