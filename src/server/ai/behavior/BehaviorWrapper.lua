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
		endTimesStamp = 0
	}, BehaviorWrapper)
end

function BehaviorWrapper.getStatus(self: BehaviorWrapper): Status
	return self.status
end

function BehaviorWrapper.tryStart(self: BehaviorWrapper, agent: Agent, currentTime: number): boolean
	if self:hasRequiredMemories(agent) and self.behavior:checkExtraStartConditions(agent) then
		self.status = BehaviorControl.Status.RUNNING
		local i = agent:getRandom():NextInteger(self.minDuration, self.maxDuration)
		self.endTimesStamp = currentTime + i
		self.behavior:doStart(agent)
		return true
	else
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
	return currentTime > self.endTimesStamp
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