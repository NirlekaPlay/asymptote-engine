--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local GoalSelector = require(ServerScriptService.server.ai.goal.GoalSelector)
local LookAtSuspectGoal = require(ServerScriptService.server.ai.goal.LookAtSuspectGoal)
local PursueTrespasserGoal = require(ServerScriptService.server.ai.goal.PursueTrespasserGoal)
local RandomPostGoal = require(ServerScriptService.server.ai.goal.RandomPostGoal)
local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local PlayerSightSensor = require(ServerScriptService.server.ai.sensing.PlayerSightSensor)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)

local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	character: Model,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	goalSelector: GoalSelector.GoalSelector,
	pathNavigation: PathNavigation.PathNavigation,
	suspicionManager: SuspicionManagement.SuspicionManagement,
	designatedPosts: { GuardPost.GuardPost },
	memories: { [MemoryModuleTypes.MemoryModuleType<any>]: ExpireableValue.ExpireableValue<any> },
	sensors: { any }
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
	self.designatedPosts = designatedPosts
	self.sensors = {
		PlayerSightSensor.new(self, 20, 180)
	}
	self.memories = {
		[MemoryModuleTypes.VISIBLE_PLAYERS] = ExpireableValue.new({}, math.huge)
	}

	return setmetatable(self, Guard)
end

function Guard.registerGoals(self: Guard): ()
	self.goalSelector:addGoal(PursueTrespasserGoal.new(self), 3)
	self.goalSelector:addGoal(RandomPostGoal.new(self, self.designatedPosts), 4)
end

function Guard.update(self: Guard, deltaTime: number): ()
	for _, sensor in  ipairs(self.sensors) do
		sensor:update()
	end
	self.suspicionManager:update(deltaTime, self.memories[MemoryModuleTypes.VISIBLE_PLAYERS].value)
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

function Guard.getPrimaryPart(self: Guard): BasePart
	return self.character.PrimaryPart :: BasePart
end

return Guard