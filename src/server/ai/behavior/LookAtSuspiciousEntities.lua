--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

--[=[
	@class LookAtSuspiciousEntities
]=]
local LookAtSuspiciousEntities = {}
LookAtSuspiciousEntities.__index = LookAtSuspiciousEntities
LookAtSuspiciousEntities.ClassName = "LookAtSuspiciousEntities"

export type LookAtSuspiciousEntities = typeof(setmetatable({} :: {
}, LookAtSuspiciousEntities))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function LookAtSuspiciousEntities.new(): LookAtSuspiciousEntities
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, LookAtSuspiciousEntities)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT
}

function LookAtSuspiciousEntities.getMemoryRequirements(self: LookAtSuspiciousEntities): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function LookAtSuspiciousEntities.checkExtraStartConditions(self: LookAtSuspiciousEntities, agent: Agent): boolean
	return true
end

function LookAtSuspiciousEntities.canStillUse(self: LookAtSuspiciousEntities, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_COMBAT_MODE)
end

function LookAtSuspiciousEntities.doStart(self: LookAtSuspiciousEntities, agent: Agent): ()
	return
end

function LookAtSuspiciousEntities.doStop(self: LookAtSuspiciousEntities, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
end

function LookAtSuspiciousEntities.doUpdate(self: LookAtSuspiciousEntities, agent: Agent, deltaTime: number): ()
	--[[
		The Agent should look at suspicious entities under these circumstances:
		1. If the Agent spots something suspicious and is curious, they continue looking 
		until the entity is fully detected or curiosity fades
		2. If they lose track but are still curious, keep looking at last known position
		3. Stop looking when curiosity fades and nothing is detected
	]]
	
	local detectionManager = agent:getDetectionManager()
	local brain = agent:getBrain()
	local presentLookTarget = brain:getMemory(MemoryModuleTypes.LOOK_TARGET)
	
	local focusTarget = detectionManager:getFocusingTarget()
	local isCurious = detectionManager:isCurious()
	local isDetecting = detectionManager:isDetecting()
	
	-- CASE 1: If we currently have a look target, decide whether to keep it
	if presentLookTarget:isPresent() then
		-- Clear look target if curiosity is gone AND there's nothing detected
		if not isCurious and not isDetecting then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			return
		end
		
		-- Keep looking at last position if we lost the focus target but are still curious
		if not focusTarget and isCurious then
			return -- Keep existing look target
		end
		
		-- Clear look target if we have a focus target but curiosity is gone
		if focusTarget and not isCurious then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			return
		end
	end
	
	-- CASE 2: No focus target and not curious - do nothing
	if not focusTarget and not isCurious then
		return
	end
	
	-- CASE 3: We have a focus target - set it as look target if conditions are met
	if focusTarget then
		local entity = EntityManager.getEntityByUuid(focusTarget.entityUuid)
		if entity then
			local detectionLevel = detectionManager:getDetectionLevel(focusTarget.entityUuid)
			
			-- Look at the entity if we're curious OR it's fully detected
			if isCurious or detectionLevel >= 1.0 then
				brain:setMemory(MemoryModuleTypes.LOOK_TARGET, focusTarget.entityUuid)
			end
		end
	end
end

return LookAtSuspiciousEntities