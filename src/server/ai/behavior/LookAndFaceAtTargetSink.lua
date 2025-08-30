--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

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
type Agent = Agent.Agent

local MEMORY_REQUIREMENTS = {
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

	return lookTarget
		:flatMap(function(targetPlayer)
			return brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
				:map(function(visible)
					return visible[targetPlayer]
				end)
		end)
		:isPresent() or lookTarget
		:flatMap(function(targetPlayer)
			return brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS)
				:map(function(hearable)
					return hearable[targetPlayer]
				end)
		end)
		:isPresent()
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
		self.lastKnownTargetPos = lookTarget:get().Character.PrimaryPart.Position
	end

	if self.lastKnownTargetPos then
		agent:getBodyRotationControl():setRotateTowards(self.lastKnownTargetPos)
		agent:getLookControl():setLookAtPos(self.lastKnownTargetPos)
	end
end

return LookAndFaceAtTargetSink