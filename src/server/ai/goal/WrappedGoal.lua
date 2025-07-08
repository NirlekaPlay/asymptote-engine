--!nonstrict

local Goal = require("./Goal")

local WrappedGoal = {}
WrappedGoal.__index = WrappedGoal

export type WrappedGoal = typeof(setmetatable({} :: {
	goal: Goal.Goal,
	priority: number,
	isGoalRunning: boolean
}, WrappedGoal))

function WrappedGoal.new(goal: Goal.Goal, priority: number)
	return setmetatable({
		goal = goal,
		priority = priority,
		isGoalRunning = false
	}, WrappedGoal)
end

function WrappedGoal.canBeReplacedBy(self: WrappedGoal, wrappedGoal: WrappedGoal): boolean
	return self.goal:isInterruptable() and wrappedGoal:getPriority() < self:getPriority()
end

function WrappedGoal.isRunning(self: WrappedGoal): boolean
	return self.isGoalRunning
end

function WrappedGoal.getPriority(self: WrappedGoal): number
	return self.priority
end

function WrappedGoal.start(self: WrappedGoal): ()
	if not self.isGoalRunning then
		self.isGoalRunning = true
		self.goal:start()
	end
end

function WrappedGoal.stop(self: WrappedGoal): ()
	if self.isGoalRunning then
		self.isGoalRunning = false
		self.goal:stop()
	end
end

return WrappedGoal