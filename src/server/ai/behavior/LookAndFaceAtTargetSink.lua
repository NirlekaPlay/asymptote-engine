--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

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

		local entityLookPos: Vector3

		-- Jesus tapdancing Christ
		-- Borderline insane entity type checking taken from VisibleEntitiesSensor.
		-- Nico what have you done.
		if entityObj.instance:IsA("BasePart") then
			entityLookPos = entityObj.instance.Position
		elseif entityObj.instance:IsA("Model") then
			entityLookPos = (entityObj.instance.PrimaryPart :: Part).Position
		end

		if entityObj.name == "Player" then
			if not entityObj.instance then return end
			if not entityObj.instance:IsA("Player") then return end
			if not entityObj.instance.Character then return end
			if not entityObj.instance.Character:IsA("Model") then return end
			if not entityObj.instance.Character.PrimaryPart then return end

			entityLookPos = entityObj.instance.Character.PrimaryPart.Position
		end

		if entityLookPos then
			self.lastKnownTargetPos = entityLookPos
		end
	end

	if self.lastKnownTargetPos then
		local agentCframe = agent:getPrimaryPart().CFrame
		local agentPos = agentCframe.Position
		--local agentForward = agentCframe.LookVector

		local toTarget = (self.lastKnownTargetPos - agentPos)
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

			if distanceToTarget > 5.5 then
				agent:getBodyRotationControl():setRotateTowards(self.lastKnownTargetPos)
			end
		end
	end

end

return LookAndFaceAtTargetSink