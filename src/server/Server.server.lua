local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local Guard = require(ServerScriptService.server.guard.Guard)
local TriggerZone = require(ServerScriptService.server.zone.TriggerZone)

local GUARD_TAG_NAME = "Guard"
local GUARD_POSTS_TAG_NAME = "Post"
local TRIGGER_ZONE_TAG_NAME = "TriggerZone"

local zones: { TriggerZone.TriggerZone } = {}
local guards: { Guard.Guard } = {}
local currentGuardPosts: { GuardPost.GuardPost } = {}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		table.insert(currentGuardPosts, newGuardPost)
	end
end

setupGuardPosts()

local function setupTriggerZones()
	for _, zone in ipairs(CollectionService:GetTagged(TRIGGER_ZONE_TAG_NAME)) do
		local newZone = TriggerZone.fromPart(zone)
		table.insert(zones, newZone)
	end
end

setupTriggerZones()

local function setupGuards()
	for _, guard in ipairs(CollectionService:GetTagged(GUARD_TAG_NAME)) do
		local newGuard = Guard.new(guard, currentGuardPosts)
		newGuard:registerGoals()
		table.insert(guards, newGuard)
	end
end

setupGuards()

RunService.PostSimulation:Connect(function(deltaTime)
	for _, zone in ipairs(zones) do
		zone:update()
	end

	for _, guard in ipairs(guards) do
		guard:update(deltaTime)
	end
end)