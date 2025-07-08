local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TriggerZone = require(ServerScriptService.server.zone.TriggerZone)

local GUARD_POSTS_TAG_NAME = "Post"
local TRIGGER_ZONE_TAG_NAME = "TriggerZone"

local zones: { TriggerZone.TriggerZone } = {}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		table.insert(currentGuardPosts, newGuardPost)
	end
end

--setupGuardPosts()

local function setupTriggerZones()
	print(CollectionService:GetTagged(TRIGGER_ZONE_TAG_NAME))
	for _, zone in ipairs(CollectionService:GetTagged(TRIGGER_ZONE_TAG_NAME)) do
		local newZone = TriggerZone.fromPart(zone)
		table.insert(zones, newZone)
	end
end

setupTriggerZones()

RunService.PostSimulation:Connect(function(deltaTime)
	for _, zone in ipairs(zones) do
		zone:update()
	end
end)
