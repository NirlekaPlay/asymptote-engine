--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")

local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
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
			"LOOKING",
			"MOVING"
		},
		agent = agent
	}, LookAtSuspectGoal)
end

function LookAtSuspectGoal.canUse(self: LookAtSuspectGoal): boolean
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	return susMan.amICurious and susMan.focusingOn
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
	if (self.agent:getNavigation() :: PathNavigation.PathNavigation).pathfinder.Status ~= "Active" then
		--print("Not active")
		self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingOn.Character.PrimaryPart.Position)
		self.agent:getLookControl():setLookAtPos(self.agent:getSuspicionManager().focusingOn.Character.PrimaryPart.Position)
	end
end

function LookAtSuspectGoal.stop(self: LookAtSuspectGoal): ()
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