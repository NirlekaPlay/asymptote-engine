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
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT
}

function ConfrontTrespasser.getMemoryRequirements(self: ConfrontTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ConfrontTrespasser.checkExtraStartConditions(self: ConfrontTrespasser, agent: Agent): boolean
	if agent:getBrain():hasMemoryValue(MemoryModuleTypes.CONFRONTING_TRESPASSER) then
		return true
	end

	local susMan = agent:getSuspicionManager()
	local trespasser: Player?
	for player, status in pairs(susMan.detectionLocks) do
		if status == "MINOR_TRESPASSING" then
			trespasser = player
			break
		end
	end

	if not trespasser then
		return false
	end

	local confrontedByAttribute = trespasser:GetAttribute(Attributes.BEING_CONFRONTED_BY_UUID.name)
	if confrontedByAttribute and confrontedByAttribute ~= agent:getUuid() then
		return false
	end

	agent:getBrain():setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, trespasser)
	trespasser:SetAttribute(Attributes.BEING_CONFRONTED_BY_UUID.name, agent:getUuid())

	return true
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	agent:getFaceControl():setFace("Angry")
	local trespasser = agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER):get():getValue()
	local trespasserWarns = trespasser:GetAttribute(Attributes.TRESPASSING_WARNS.name) :: number
	if trespasserWarns == nil then
		trespasserWarns = 0
		trespasser:SetAttribute(Attributes.TRESPASSING_WARNS.name, trespasserWarns)
	end

	trespasserWarns += 1
	trespasser:SetAttribute(Attributes.TRESPASSING_WARNS.name, trespasserWarns)
	self.patienceCooldown = 5
	agent:getBubbleChatControl():displayBubble(agent:getTrespasserEncounterDialogue(trespasser, trespasserWarns))
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	print("stopping")
	return
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local trespasser = agent:getBrain():getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER):get():getValue()
	local trespasserWarns = trespasser:GetAttribute(Attributes.TRESPASSING_WARNS.name) :: number
	local isStillTrespassing = PlayerStatusRegistry.getPlayerStatuses(trespasser):getHighestPriorityStatus() == "MINOR_TRESPASSING"

	if self.patienceCooldown <= 0 and not (trespasserWarns >= MAX_WARNS) then
		if isStillTrespassing then
			self.patienceCooldown = 5
			trespasserWarns += 1
			trespasser:SetAttribute(Attributes.TRESPASSING_WARNS.name, trespasserWarns)
		else
			trespasser:SetAttribute(Attributes.BEING_CONFRONTED_BY_UUID.name, nil)
			agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
		end
	else
		self.patienceCooldown -= deltaTime
		return
	end

	agent:getBubbleChatControl():displayBubble(agent:getTrespasserEncounterDialogue(trespasser, trespasserWarns))
	if trespasserWarns >= MAX_WARNS then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, trespasser)
	end
end

return ConfrontTrespasser