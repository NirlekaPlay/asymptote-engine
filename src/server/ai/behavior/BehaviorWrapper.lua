--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Behavior = require(script.Parent.Behavior)
local BehaviorControl = require(script.Parent.BehaviorControl)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

local BehaviorWrapper = {}
BehaviorWrapper.__index = BehaviorWrapper

export type BehaviorWrapper = typeof(setmetatable({} :: {
	status: Status,
	behavior: Behavior,
	endTimesStamp: number,
	reactionTimer: number?,
	minDuration: number,
	maxDuration: number
}, BehaviorWrapper))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Behavior = Behavior.Behavior
type Agent = Agent.Agent

function BehaviorWrapper.new(behavior: Behavior): BehaviorWrapper
	return setmetatable({
		status = BehaviorControl.Status.STOPPED :: Status,
		behavior = behavior,
		minDuration = behavior.minDuration or 60,
		maxDuration = behavior.maxDuration or 60,
		reactionTimer = nil,
		endTimesStamp = 0,
		name = behavior.ClassName or "UntitledBehavior"
	}, BehaviorWrapper)
end

function BehaviorWrapper.getStatus(self: BehaviorWrapper): Status
	return self.status
end

function BehaviorWrapper.tryStart(self: BehaviorWrapper, agent: Agent, currentTime: number, deltaTime: number): boolean
	if not self:hasRequiredMemories(agent) then
		self.reactionTimer = nil
		return false
	end

	if self.behavior:checkExtraStartConditions(agent) then
		local requiredReaction = 0
		if self.behavior.getReactionTime then
			requiredReaction = self.behavior:getReactionTime(agent, deltaTime) or 0
		end


		if requiredReaction <= 0 then
			self.status = BehaviorControl.Status.RUNNING
			local i = agent:getRandom():NextInteger(self.minDuration, self.maxDuration)
			self.endTimesStamp = currentTime + i
			self.behavior:doStart(agent)
			return true
		end

		if self.reactionTimer == nil then
			self.reactionTimer = requiredReaction
		end

		self.reactionTimer -= deltaTime

		if self.reactionTimer <= 0 then
			self.reactionTimer = nil
			self.status = BehaviorControl.Status.RUNNING

			local i = agent:getRandom():NextInteger(self.minDuration, self.maxDuration)
			self.endTimesStamp = currentTime + i
			self.behavior:doStart(agent)
			return true
		end

		return false
	else
		self.reactionTimer = nil
		return false
	end
end

function BehaviorWrapper.updateOrStop(self: BehaviorWrapper, agent: Agent, currentTime: number, deltaTime: number): ()
	if not self:isTimedOut(currentTime) and self.behavior:canStillUse(agent) then
		self.behavior:doUpdate(agent, deltaTime)
	else
		self:stop(agent)
	end
end

function BehaviorWrapper.stop(self: BehaviorWrapper, agent: Agent): ()
	self.status = BehaviorControl.Status.STOPPED
	self.behavior:doStop(agent)
end

function BehaviorWrapper.isTimedOut(self: BehaviorWrapper, currentTime: number): boolean
	if self.minDuration == math.huge or self.maxDuration == math.huge then
		return false
	else
		return currentTime > self.endTimesStamp
	end
end

function BehaviorWrapper.hasRequiredMemories(self: BehaviorWrapper, agent: Agent): boolean
	for memoryType, memoryStatus in pairs(self.behavior:getMemoryRequirements()) do
		if not agent:getBrain():checkMemory(memoryType, memoryStatus) then
			return false
		end
	end

	return true
end

return BehaviorWrapper