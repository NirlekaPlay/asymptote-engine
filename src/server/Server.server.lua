local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local GoalSelector = require(ServerScriptService.server.ai.goal.GoalSelector)
local RandomPostGoal = require(ServerScriptService.server.ai.goal.RandomPostGoal)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local TargetNearbySensor = require(ServerScriptService.server.ai.sensing.TargetNearbySensor)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local TriggerZone = require(ServerScriptService.server.zone.TriggerZone)

type GuardPost = GuardPost.GuardPost

local GUARD_POSTS_TAG_NAME = "Post"

local rig: Model = workspace:WaitForChild("Rig")
local currentSusMan = SuspicionManagement.new(rig)
local currentNearbySensor = TargetNearbySensor.new(20)
local currentTriggerZone = TriggerZone.fromPart(workspace:WaitForChild("Zone1"))
local currentBodyRotCtrl = BodyRotationControl.new(rig.HumanoidRootPart)
local currentPathNav = PathNavigation.new(rig)
local currentGoalSelector = GoalSelector.new()

local currentGuardPosts: { GuardPost } = {}

local GuardAgent = {
	getSuspicionManager = function()
		return currentSusMan
	end,
	getBodyRotationControl = function()
		return currentBodyRotCtrl
	end,
	getNavigation = function()
		return currentPathNav
	end
}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		table.insert(currentGuardPosts, newGuardPost)
	end
end

setupGuardPosts()

currentGoalSelector:addGoal(RandomPostGoal.new(GuardAgent, currentGuardPosts), 1)

RunService.PreAnimation:Connect(function(deltaTime)
	currentTriggerZone:update()
	currentNearbySensor:update(rig.PrimaryPart.Position, currentTriggerZone:getPlayersInZone())
	currentSusMan:update(deltaTime, currentNearbySensor.detectedTargets)
	currentGoalSelector:update(deltaTime)
	
end)