--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
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
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	return susMan:isCurious()
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
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	if self.agent.character.Head.QuestionMarkIcon then
		self.agent.character.Head.QuestionMarkIcon.Enabled = true
	end

	if susMan:getFocusingTarget() then
		self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingOn.Character.PrimaryPart.Position)
		self.agent:getLookControl():setLookAtPos(self.agent:getSuspicionManager().focusingOn.Character.PrimaryPart.Position)
	end
end

function LookAtSuspectGoal.stop(self: LookAtSuspectGoal): ()
	if self.agent.character.Head.QuestionMarkIcon then
		self.agent.character.Head.QuestionMarkIcon.Enabled = false
	end
	self.agent:getBodyRotationControl():setRotateTowards(nil)
	self.agent:getLookControl():setLookAtPos(nil)
end

function LookAtSuspectGoal.update(self: LookAtSuspectGoal, deltaTime: number): ()
	self:start()
end

function LookAtSuspectGoal.requiresUpdating(self: LookAtSuspectGoal): boolean
	return true
end

return LookAtSuspectGoal