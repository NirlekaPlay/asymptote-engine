--!nonstrict

local Goal = require("./Goal")

local LookAtSuspectGoal = {}
LookAtSuspectGoal.__index = LookAtSuspectGoal

export type LookAtSuspectGoal = typeof(setmetatable({} :: {
	agent: any
}, LookAtSuspectGoal)) & Goal.Goal

function LookAtSuspectGoal.new(agent): LookAtSuspectGoal
	return setmetatable({
		flags = {
			"LOOKING"
		},
		agent = agent
	}, LookAtSuspectGoal)
end

function LookAtSuspectGoal.canUse(self: LookAtSuspectGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	return susMan.currentState == "SUSPICIOUS" or susMan.currentState == "ALERTED"
end

function LookAtSuspectGoal.canContinueToUse(self: LookAtSuspectGoal): boolean
	return self:canUse()
end

function LookAtSuspectGoal.isInterruptable(self: LookAtSuspectGoal): boolean
	return true
end

function LookAtSuspectGoal.getFlags(self: LookAtSuspectGoal): {Flag}
	return self.flags
end

function LookAtSuspectGoal.start(self: LookAtSuspectGoal): ()
	self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingSuspect.Character.PrimaryPart.Position)
end

function LookAtSuspectGoal.stop(self: LookAtSuspectGoal): ()
	self.agent:getBodyRotationControl():setRotateTowards(nil)
end

function LookAtSuspectGoal.update(self: LookAtSuspectGoal, deltaTime: number): ()
	self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingSuspect.Character.PrimaryPart.Position)
end

function LookAtSuspectGoal.requiresUpdating(self: LookAtSuspectGoal): boolean
	return true
end

return LookAtSuspectGoal