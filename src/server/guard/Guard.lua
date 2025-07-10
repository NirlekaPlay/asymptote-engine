--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local GoalSelector = require(ServerScriptService.server.ai.goal.GoalSelector)
local LookAtSuspectGoal = require(ServerScriptService.server.ai.goal.LookAtSuspectGoal)
local RandomPostGoal = require(ServerScriptService.server.ai.goal.RandomPostGoal)
local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local TargetNearbySensor = require(ServerScriptService.server.ai.sensing.TargetNearbySensor)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)

local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	character: Model,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	goalSelector: GoalSelector.GoalSelector,
	pathNavigation: PathNavigation.PathNavigation,
	suspicionManager: SuspicionManagement.SuspicionManagement,
	targetNearbySensor: TargetNearbySensor.TargetNearbySensor,
	designatedPosts: { GuardPost.GuardPost },
	memories: { [MemoryModuleTypes.MemoryModuleType<any>]: ExpireableValue.ExpireableValue<any> }
}, Guard))

function Guard.new(character: Model, designatedPosts: { GuardPost.GuardPost }): Guard
	local self = {}

	self.character = character
	self.bodyRotationControl = BodyRotationControl.new(character)
	self.goalSelector = GoalSelector.new()
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 8,
		AgentHeight = 8
	})
	self.suspicionManager = SuspicionManagement.new(character)
	self.targetNearbySensor = TargetNearbySensor.new(20)
	self.designatedPosts = designatedPosts

	return setmetatable(self, Guard)
end

function Guard.registerGoals(self: Guard): ()
	self.goalSelector:addGoal(LookAtSuspectGoal.new(self), 3)
	self.goalSelector:addGoal(RandomPostGoal.new(self, self.designatedPosts), 4)
end

function Guard.update(self: Guard, deltaTime: number): ()
	self.targetNearbySensor:update(self.character.PrimaryPart.Position)
	self.suspicionManager:update(deltaTime, self.targetNearbySensor.detectedTargets)
	self.goalSelector:update(deltaTime)
	self.bodyRotationControl:update(deltaTime)
end

function Guard.getNavigation(self: Guard): PathNavigation.PathNavigation
	return self.pathNavigation
end

function Guard.getSuspicionManager(self: Guard): SuspicionManagement.SuspicionManagement
	return self.suspicionManager
end

function Guard.getBodyRotationControl(self: Guard): BodyRotationControl.BodyRotationControl
	return self.bodyRotationControl
end

return Guard