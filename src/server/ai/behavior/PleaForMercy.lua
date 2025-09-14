--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PanicDialogues = require(ReplicatedStorage.shared.dialogue.PanicDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class PleaForMercy
]=]
local PleaForMercy = {}
PleaForMercy.__index = PleaForMercy
PleaForMercy.ClassName = "PleaForMercy"

export type PleaForMercy = typeof(setmetatable({} :: {
	alreadyRun: boolean
}, PleaForMercy))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function PleaForMercy.new(): PleaForMercy
	return setmetatable({
		minDuration = 1,
		maxDuration = 1,
		alreadyRun = false
	}, PleaForMercy)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID] = MemoryStatus.VALUE_PRESENT
}

local DIALOGUE_PER_PLAYER_STATUS = {
	[PlayerStatusTypes.ARMED] = "status_armed",
	[PlayerStatusTypes.DANGEROUS_ITEM] = "status_dangerous_item"
}

function PleaForMercy.getMemoryRequirements(self: PleaForMercy): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function PleaForMercy.checkExtraStartConditions(self: PleaForMercy, agent: Agent): boolean
	return not self.alreadyRun
end

function PleaForMercy.canStillUse(self: PleaForMercy, agent: Agent): boolean
	return false
end

function PleaForMercy.doStart(self: PleaForMercy, agent: Agent): ()
	self.alreadyRun = true
	local panicSourceEntityUuid = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID):get()
	local panicSourceEntityObj = EntityManager.getEntityByUuid(panicSourceEntityUuid)
	if not panicSourceEntityObj then
		return
	end

	-- TODO: Make this expandable.
	if not panicSourceEntityObj.isStatic and panicSourceEntityObj.name == "Player" then
		local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(panicSourceEntityObj.instance :: Player)
		if not playerStatusHolder then
			return
		end
		local highestPriorityStatus = playerStatusHolder:getHighestPriorityStatus()
		if not highestPriorityStatus then
			return
		end

		local dialogueKey = DIALOGUE_PER_PLAYER_STATUS[highestPriorityStatus]
		if dialogueKey then
			local agentName = agent:getCharacterName()
			if not agentName then
				agent:getTalkControl():sayRandomSequences(PanicDialogues.guardPanicGeneric[dialogueKey])
			end
		end
	else
		if panicSourceEntityObj.name == "C4" then
			local agentName = agent:getCharacterName()
			if not agentName then
				agent:getTalkControl():sayRandomSequences(PanicDialogues.guardPanicGeneric["entity_c4"])
			end
		end
	end
end

function PleaForMercy.doStop(self: PleaForMercy, agent: Agent): ()
	return
end

function PleaForMercy.doUpdate(self: PleaForMercy, agent: Agent, deltaTime: number): ()
	return
end

return PleaForMercy