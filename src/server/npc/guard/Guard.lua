--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local Brain = require(ServerScriptService.server.ai.Brain)
local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local LookAndFaceAtTarget = require(ServerScriptService.server.ai.behavior.LookAndFaceAtTarget)
local SetLookAtSusiciousPlayer = require(ServerScriptService.server.ai.behavior.SetLookAtSusiciousPlayer)
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local BubbleChatControl = require(ServerScriptService.server.ai.control.BubbleChatControl)
local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local GunControl = require(ServerScriptService.server.ai.control.GunControl)
local LookControl = require(ServerScriptService.server.ai.control.LookControl)
local GoalSelector = require(ServerScriptService.server.ai.goal.GoalSelector)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local SensorTypes = require(ServerScriptService.server.ai.sensing.SensorTypes)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)


local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	character: Model,
	alive: boolean,
	brain: Brain.Brain<Agent.Agent>,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	gunControl: GunControl.GunControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
	goalSelector: GoalSelector.GoalSelector,
	pathNavigation: PathNavigation.PathNavigation,
	suspicionManager: SuspicionManagement.SuspicionManagement,
	designatedPosts: { GuardPost.GuardPost }
}, Guard))

function Guard.new(character: Model, designatedPosts: { GuardPost.GuardPost }): Guard
	local self = {}

	self.character = character
	self.alive = true
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 6,
		AgentHeight = 6
	})
	self.bodyRotationControl = BodyRotationControl.new(character, self.pathNavigation)
	self.suspicionManager = SuspicionManagement.new(self)
	self.designatedPosts = designatedPosts
	self.gunControl = GunControl.new(self)
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
	self.brain = Brain.new(self, {
		MemoryModuleTypes.LOOK_TARGET
	}, { SensorTypes.VISIBLE_PLAYERS_SENSOR })
	self.brain:addActivity(Activity.CORE, 0, {
		SetLookAtSusiciousPlayer.new(),
		LookAndFaceAtTarget.new()
	})
	self.brain:setDefaultActivity(Activity.CORE)
	self.brain:useDefaultActivity()

	return setmetatable(self, Guard)
end

function Guard.update(self: Guard, deltaTime: number): ()
	if not self:isAlive() then
		self.suspicionManager:decaySuspicionOnAllPlayers(deltaTime)
		return
	end

	self.brain:update(deltaTime)
	local visiblePlayers = self.brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
	if visiblePlayers:isPresent() then
		visiblePlayers = visiblePlayers:get():getValue()
	else
		visiblePlayers = {}
	end
	self.suspicionManager:update(deltaTime, visiblePlayers)
	self.bodyRotationControl:update(deltaTime)
	self.lookControl:update()

	if self.pathNavigation.pathfinder.Status == "Active" then
		self.isPathfindingValue.Value = true
	else
		self.isPathfindingValue.Value = false
	end
end

function Guard.canDetectThroughDisguises(self: Guard): boolean
	return self.character:GetAttribute("CanSeeThroughDisguises")
end

function Guard.canBeIntimidated(self: Guard): boolean
	return self.character:GetAttribute("CanBeIntimidated")
end

function Guard.onDied(self: Guard)
	self.faceControl:setFace("Unconscious")
end

function Guard.isAlive(self: Guard): boolean
	return self.alive
end

function Guard.getBrain(self: Guard): Brain.Brain<Agent.Agent>
	return self.brain
end

function Guard.getGunControl(self: Guard): GunControl.GunControl
	return self.gunControl
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