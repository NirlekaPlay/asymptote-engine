--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class LookAtSuspiciousPlayer
]=]
local LookAtSuspiciousPlayer = {}
LookAtSuspiciousPlayer.__index = LookAtSuspiciousPlayer
LookAtSuspiciousPlayer.ClassName = "LookAtSuspiciousPlayer"

export type LookAtSuspiciousPlayer = typeof(setmetatable({} :: {
}, LookAtSuspiciousPlayer))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function LookAtSuspiciousPlayer.new(): LookAtSuspiciousPlayer
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, LookAtSuspiciousPlayer)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.REGISTERED
}

function LookAtSuspiciousPlayer.getMemoryRequirements(self: LookAtSuspiciousPlayer): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function LookAtSuspiciousPlayer.checkExtraStartConditions(self: LookAtSuspiciousPlayer, agent: Agent): boolean
	return true
end

function LookAtSuspiciousPlayer.canStillUse(self: LookAtSuspiciousPlayer, agent: Agent): boolean
	return true
end

function LookAtSuspiciousPlayer.doStart(self: LookAtSuspiciousPlayer, agent: Agent): ()
	return
end

function LookAtSuspiciousPlayer.doStop(self: LookAtSuspiciousPlayer, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
end

function LookAtSuspiciousPlayer.doUpdate(self: LookAtSuspiciousPlayer, agent: Agent, deltaTime: number): ()
	--[[
		The Agent should only look, under these circumstances for example:
		
		1. If the Agent spots something suspicious and isCurious is true,
		they will continue looking until the suspect is fully detected,
		which is handled in a seperate logic, or in case where it loose tracks
		of the suspect, it will continue looking at that last position until
		isCurious is false.
	]]
	local susMan = agent:getSuspicionManager()
	local suspect = susMan:getFocusingTarget()
	local isCurious = susMan:isCurious()
	local isDetectedStatusesEmpty = next(susMan.detectedStatuses) == nil
	local brain = agent:getBrain()
	local presentLookTarget = brain:getMemory(MemoryModuleTypes.LOOK_TARGET)

	-- CASE 1: If we currently have a look target
	if presentLookTarget:isPresent() then
		-- If curiosity is gone AND there's nothing detected, stop looking entirely.
		if not isCurious and isDetectedStatusesEmpty then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			return
		end

		-- If we have lost track of the suspect but are still curious, keep the LOOK_TARGET.
		-- This keeps the agent looking at the last known position.
		if not suspect and isCurious then
			return
		end

		-- If we have a suspect but curiosity is gone, stop looking.
		if suspect and not isCurious then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			return
		end
	end

	-- CASE 2: If there’s no suspect and curiosity is gone, do nothing further.
	if not suspect and not isCurious then
		return
	end

	-- CASE 3: If we have a suspect or are curious, evaluate suspicion level.
	if suspect then
		local playerStatuses = PlayerStatusRegistry.getPlayerStatuses(suspect)
		if playerStatuses then
			local highestStatus = playerStatuses:getHighestPriorityStatus()
			local highestStatusValue = susMan.suspicionLevels[suspect][highestStatus]

			if isCurious or (highestStatusValue and highestStatusValue >= 1) then
				brain:setNullableMemory(MemoryModuleTypes.LOOK_TARGET, suspect)
			end
		end
	end
end

return LookAtSuspiciousPlayer