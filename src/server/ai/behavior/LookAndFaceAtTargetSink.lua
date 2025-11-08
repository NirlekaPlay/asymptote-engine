--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)

local LookAndFaceAtTargetSink = {}
LookAndFaceAtTargetSink.__index = LookAndFaceAtTargetSink
LookAndFaceAtTargetSink.ClassName = "LookAndFaceAtTargetSink"

export type LookAndFaceAtTargetSink = typeof(setmetatable({} :: {
	lastKnownTargetPos: Vector3?,
}, LookAndFaceAtTargetSink))

function LookAndFaceAtTargetSink.new(): LookAndFaceAtTargetSink
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		lastKnownTargetPos = nil :: Vector3?,
	}, LookAndFaceAtTargetSink)
end

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ReporterAgent.ReporterAgent

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.VISIBLE_ENTITIES] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.HEARABLE_PLAYERS] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.REGISTERED
}

function LookAndFaceAtTargetSink.getMemoryRequirements(self: LookAndFaceAtTargetSink): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function LookAndFaceAtTargetSink.checkExtraStartConditions(self: LookAndFaceAtTargetSink, agent: Agent): boolean
	return true
end

function LookAndFaceAtTargetSink.canStillUse(self: LookAndFaceAtTargetSink, agent: Agent.Agent): boolean
	if self.lastKnownTargetPos then
		if not agent:getBodyRotationControl().dotThresholdReached then
			return true
		end
	end

	local brain = agent:getBrain()
	local lookTarget = brain:getMemory(MemoryModuleTypes.LOOK_TARGET)
	local visibleEntities = brain:getMemory(MemoryModuleTypes.VISIBLE_ENTITIES):orElse({})
	local hearingPlayers = brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS):orElse({})

	local result = lookTarget
		:map(function(targetUuid)
			if visibleEntities[targetUuid] ~= nil then
				return true
			end

			local entityObj = EntityManager.getEntityByUuid(targetUuid)
			if entityObj and not entityObj.isStatic and entityObj.name == "Player" then
				return hearingPlayers[entityObj.instance :: Player] ~= nil
			end

			return false
		end)
		:orElse(false) :: boolean

	return result
end

function LookAndFaceAtTargetSink.doStart(self: LookAndFaceAtTargetSink, agent: Agent): ()
	self.lastKnownTargetPos = nil
end

function LookAndFaceAtTargetSink.doStop(self: LookAndFaceAtTargetSink, agent: Agent): ()
	self.lastKnownTargetPos = nil
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
	--agent:getBodyRotationControl():setRotateTowards(nil)
	agent:getLookControl():setLookAtPos(nil)
end

function LookAndFaceAtTargetSink.doUpdate(self: LookAndFaceAtTargetSink, agent: Agent, deltaTime: number): ()
	local lookTarget = agent:getBrain():getMemory(MemoryModuleTypes.LOOK_TARGET)

	if lookTarget:isPresent() then
		local entityUuid = lookTarget:get()
		local entityObj = EntityManager.getEntityByUuid(entityUuid)
		if not entityObj or entityObj.isStatic then
			return
		end

		self.lastKnownTargetPos = EntityUtils.getPos(entityObj)
	end

	if self.lastKnownTargetPos then
		local agentCFrame = agent:getPrimaryPart().CFrame
		local agentPos = agentCFrame.Position
		local agentForward = agentCFrame.LookVector
		local toTarget = self.lastKnownTargetPos - agentPos
		local isBehind = toTarget:Dot(agentForward) < 0

		local distance = toTarget.Magnitude
		if distance > 0 then
			local distanceToTarget = (agentPos - self.lastKnownTargetPos).Magnitude
			--[[
			local BODY_ROTATION_THRESHOLD_DEGREES = 30
			toTarget = toTarget.Unit

			local dot = agentForward:Dot(toTarget)
			local angle = math.acos(math.clamp(dot, -1, 1)) -- radians

			local angleThreshold = math.rad(BODY_ROTATION_THRESHOLD_DEGREES)
			if angle > angleThreshold then
				agent:getBodyRotationControl():setRotateTowards(self.lastKnownTargetPos)
			end]]

			-- TODO: Should be in a predicate function or something
			if not agent:getReportControl():isRadioEquipped() then
				agent:getLookControl():setLookAtPos(self.lastKnownTargetPos)
			else
				agent:getLookControl():setLookAtPos(nil)
			end

			if (distanceToTarget > 5.5) or isBehind then
				agent:getBodyRotationControl():setRotateTowards(self.lastKnownTargetPos)
			end
		end
	end

end

return LookAndFaceAtTargetSink