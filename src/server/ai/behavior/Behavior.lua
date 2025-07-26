--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local BehaviorControl = require(script.Parent.BehaviorControl)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

local Behavior = {}
Behavior.__index = Behavior

export type Behavior = typeof(setmetatable({} :: {
	status: Status,
	entryCondition: { [MemoryModuleType<any>]: MemoryStatus },
	endTimesStamp: number,
	minDuration: number,
	maxDuration: number
}, Behavior))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function Behavior.new(entryCondition: { [MemoryModuleType<any>]: MemoryStatus }, minDur: number?, maxDur: number?): Behavior
	return setmetatable({
		status = BehaviorControl.Status.STOPPED :: Status,
		entryCondition = entryCondition,
		minDuration = minDur or 60,
		maxDuration = maxDur or 60,
		endTimesStamp = 0
	}, Behavior)
end

function Behavior.getStatus(self: Behavior): Status
	return self.status
end

function Behavior.tryStart(self: Behavior, agent: Agent, currentTime: number): boolean
	if self:hasRequiredMemories(agent) and self:checkExtraStartConditions(agent) then
		self.status = BehaviorControl.Status.RUNNING
		local i = agent:getRandom():NextInteger(self.maxDuration, self.maxDuration)
		self.endTimesStamp = currentTime + i
		self:doStart()
		return true
	else
		return false
	end
end

function Behavior.doStart(self: Behavior): ()
	return
end

function Behavior.updateOrStop(self: Behavior, agent: Agent, currentTime: number): ()
	if not self:isTimedOut(currentTime) and self:canStillUse(agent) then
		self:doUpdate(agent)
	else
		self:stop(agent)
	end
end

function Behavior.doUpdate(self: Behavior, agent: Agent): ()
	return
end

function Behavior.stop(self: Behavior, agent: Agent): ()
	self.status = BehaviorControl.Status.STOPPED
	self:doStop(agent)
end

function Behavior.doStop(self: Behavior, agent: Agent): ()
	return
end

function Behavior.canStillUse(self: Behavior, agent: Agent): boolean
	return false
end

function Behavior.isTimedOut(self: Behavior, currentTime: number): boolean
	return currentTime > self.endTimesStamp
end

function Behavior.checkExtraStartConditions(self: Behavior, agent: Agent): boolean
	return true
end

function Behavior.hasRequiredMemories(self: Behavior, agent: Agent): boolean
	for memoryType, memoryStatus in pairs(self.entryCondition) do
		local agentBrain = agent:getBrain()
		if not agentBrain:checkMemory(memoryType, memoryStatus) then
			return false
		end
	end

	return true
end

return Behavior