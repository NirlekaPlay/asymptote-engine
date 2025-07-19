--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ShockedGoal = require("../ai/goal/ShockedGoal")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local BubbleChatControl = require(ServerScriptService.server.ai.control.BubbleChatControl)
local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local LookControl = require(ServerScriptService.server.ai.control.LookControl)
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
	alive: boolean,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
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
	self.alive = true
	self.goalSelector = GoalSelector.new()
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 8,
		AgentHeight = 8
	})
	self.bodyRotationControl = BodyRotationControl.new(character, self.pathNavigation)
	self.suspicionManager = SuspicionManagement.new(character)
	self.designatedPosts = designatedPosts
	self.sensors = {
		PlayerSightSensor.new(self, 20, 180)
	}
	self.memories = {
		[MemoryModuleTypes.VISIBLE_PLAYERS] = ExpireableValue.new({}, math.huge)
	}
	self.lookControl = LookControl.new(character)
	self.faceControl = FaceControl.new(character)
	self.faceControl:setFace("Neutral")
	self.bubbleChatControl = BubbleChatControl.new(character)

	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	humanoid.Died:Once(function()
		self.alive = false
		self:onDied()
	end)

	-- to fix the motherfucking shitty ass walk animation
	local isPathfinding = character:FindFirstChild("isPathfinding")
	
	if not isPathfinding then
		isPathfinding = Instance.new("BoolValue")
		isPathfinding.Value = false
		isPathfinding.Name = "isPathfinding"
		isPathfinding.Parent = character
	end

	self.isPathfindingValue = isPathfinding

	return setmetatable(self, Guard)
end

function Guard.registerGoals(self: Guard): ()
	self.goalSelector:addGoal(ShockedGoal.new(self), 1)
	self.goalSelector:addGoal(LookAtSuspectGoal.new(self), 2)
	self.goalSelector:addGoal(PursueTrespasserGoal.new(self), 3)
	self.goalSelector:addGoal(RandomPostGoal.new(self, self.designatedPosts), 4)
end

function Guard.update(self: Guard, deltaTime: number): ()
	if not self:isAlive() then
		self.suspicionManager:decaySuspicionOnAllPlayers(deltaTime)
		return
	end

	for _, sensor in  ipairs(self.sensors) do
		sensor:update()
	end
	self.suspicionManager:update(deltaTime, self.memories[MemoryModuleTypes.VISIBLE_PLAYERS].value)
	self.goalSelector:update(deltaTime)
	self.bodyRotationControl:update(deltaTime)
	self.lookControl:update()

	if self.pathNavigation.pathfinder.Status == "Active" then
		self.isPathfindingValue.Value = true
	else
		self.isPathfindingValue.Value = false
	end

	if not self.memories.IS_DEALING_WITH_SOMETHING_HERE then
		self.memories.IS_DEALING_WITH_SOMETHING_HERE = ExpireableValue.nonExpiring(false)
	end

	if not self.memories.IS_DEALING_WITH_SOMETHING_HERE.value then
		for player, expireableValue in pairs(self.memories.WARNED_PLAYERS) do
			if expireableValue:isExpired() then
				self.memories.WARNED_PLAYERS[player] = nil
				continue
			end
			expireableValue:update(deltaTime)
		end
	end
end

function Guard.onDied(self: Guard)
	self.faceControl:setFace("Unconscious")
	self.goalSelector:stopAllRunningGoals()
end

function Guard.isAlive(self: Guard): boolean
	return self.alive
end

function Guard.getFaceControl(self: Guard): FaceControl.FaceControl
	return self.faceControl
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

function Guard.getLookControl(self: Guard): LookControl.LookControl
	return self.lookControl
end

function Guard.getBubbleChatControl(self: Guard): BubbleChatControl.BubbleChatControl
	return self.bubbleChatControl
end

function Guard.getPrimaryPart(self: Guard): BasePart
	return self.character.PrimaryPart :: BasePart
end

return Guard