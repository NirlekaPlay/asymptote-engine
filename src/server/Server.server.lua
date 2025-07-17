local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local Guard = require(ServerScriptService.server.guard.Guard)
local Statuses = require(ServerScriptService.server.player.Statuses)
local TrespassingZone = require(ServerScriptService.server.zone.TrespassingZone)

local GUARD_TAG_NAME = "Guard"
local GUARD_POSTS_TAG_NAME = "Post"
local MINOR_TRESPASSING_ZONE_TAG_NAME = "MinorTrespassingZone"
local MAJOR_TRESPASSING_ZONE_TAG_NAME = "MajorTrespassingZone"

local MINOR_TRESPASSING_CONFIG: TrespassingZone.ZoneConfig = {
	penalties = {
		disguised = nil,
		undisguised = Statuses.PLAYER_STATUSES.MINOR_TRESPASSING
	}
}

local MAJOR_TRESPASSING_ZONE: TrespassingZone.ZoneConfig = {
	penalties = {
		disguised = Statuses.PLAYER_STATUSES.MINOR_TRESPASSING,
		undisguised = Statuses.PLAYER_STATUSES.MAJOR_TRESPASSING
	}
}

local zones: { TrespassingZone.TrespassingZone } = {}
local guards: { [Model]: Guard.Guard } = {}
local currentGuardPosts: { GuardPost.GuardPost } = {}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		table.insert(currentGuardPosts, newGuardPost)
	end
end

setupGuardPosts()

local function setupTrespassingZones()
	for _, zone in ipairs(CollectionService:GetTagged(MINOR_TRESPASSING_ZONE_TAG_NAME)) do
		local newZone = TrespassingZone.fromPart(zone, MINOR_TRESPASSING_CONFIG)
		table.insert(zones, newZone)
	end

	for _, zone in ipairs(CollectionService:GetTagged(MAJOR_TRESPASSING_ZONE_TAG_NAME)) do
		local newZone = TrespassingZone.fromPart(zone, MAJOR_TRESPASSING_ZONE)
		table.insert(zones, newZone)
	end
end

setupTrespassingZones()

local function setupGuards()
	for _, guard in ipairs(CollectionService:GetTagged(GUARD_TAG_NAME)) do
		local humanoid = guard:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				--guards[guard]:destroy()
				--guards[guard] = nil
			end)
		end
		local newGuard = Guard.new(guard, currentGuardPosts)
		newGuard:registerGoals()
		guards[guard] = newGuard
	end
end

setupGuards()

RunService.PostSimulation:Connect(function(deltaTime)
	for _, zone in ipairs(zones) do
		zone:update()
	end

	for model, guard in pairs(guards) do
		guard:update(deltaTime)
	end
end)