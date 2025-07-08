--!strict

local Goal = {}
Goal.__index = Goal

export type Goal = typeof(setmetatable({} :: {
	flags: {any}
}, Goal))

function Goal.new(flags: {any}): Goal
	return setmetatable({
		flags = flags or {}
	}, Goal)
end

function Goal.canUse(self: Goal): boolean
	return false
end

function Goal.canContinueToUse(self: Goal): boolean
	return true
end

function Goal.isInterruptable(self: Goal): boolean
	return true
end

function Goal.getFlags(self: Goal): {Flag}
	return self.flags
end

function Goal.start(self: Goal): ()
	return
end

function Goal.stop(self: Goal): ()
	return
end

function Goal.update(self: Goal, delta: number?): ()
	return
end

function Goal.requiresUpdating(self: Goal): boolean
	return false
end

return Goal
