local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local PlayerStatusRegistry = require("./player/PlayerStatusRegistry")
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local Guard = require(ServerScriptService.server.npc.guard.Guard)
local TrespassingZone = require(ServerScriptService.server.zone.TrespassingZone)

local GUARD_TAG_NAME = "Guard"
local GUARD_POSTS_TAG_NAME = "Post"
local MINOR_TRESPASSING_ZONE_TAG_NAME = "MinorTrespassingZone"
local MAJOR_TRESPASSING_ZONE_TAG_NAME = "MajorTrespassingZone"

local MINOR_TRESPASSING_CONFIG: TrespassingZone.ZoneConfig = {
	penalties = {
		disguised = nil,
		undisguised = "MINOR_TRESPASSING"
	}
}

local MAJOR_TRESPASSING_ZONE: TrespassingZone.ZoneConfig = {
	penalties = {
		disguised = "MINOR_TRESPASSING",
		undisguised = "MAJOR_TRESPASSING"
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
		if guard.Parent ~= workspace then
			continue
		end
		local newGuard = Guard.new(guard, currentGuardPosts)
		guards[guard] = newGuard
	end
end

setupGuards()

CollectionService:GetInstanceAddedSignal(GUARD_TAG_NAME):Connect(function(guard)
	if guard.Parent ~= workspace then
		local connection: RBXScriptConnection
		connection = guard:GetPropertyChangedSignal("Parent"):Connect(function()
			if guard.Parent == workspace then
				connection:Disconnect()
				local newGuard = Guard.new(guard, currentGuardPosts)
				guards[guard] = newGuard
			end
		end)
		return
	end

	local newGuard = Guard.new(guard, currentGuardPosts)
	guards[guard] = newGuard
end)

RunService.PostSimulation:Connect(function(deltaTime)
	for _, zone in ipairs(zones) do
		zone:update()
	end

	-- this frame, is there any listening clients?
	local hasListeningClients = DebugPackets.hasListeningClients(DebugPackets.Packets.DEBUG_BRAIN)
	for model, guard in pairs(guards) do
		if not model.PrimaryPart then
			guards[model] = nil
			model.Parent = nil
			continue
		end

		if not guard:isAlive() then
			guards[model] = nil
			continue
		end

		guard:update(deltaTime)
		if hasListeningClients then
			DebugPackets.queueDataToBatch(DebugPackets.Packets.DEBUG_BRAIN, DebugPackets.createBrainDump(guard))
		end
	end
	if hasListeningClients then
		DebugPackets.flushBrainDumpsToListeningClients()
	end
end)

if not PhysicsService:IsCollisionGroupRegistered("NonCollideWithPlayer") then
	PhysicsService:RegisterCollisionGroup("NonCollideWithPlayer")
end
PhysicsService:CollisionGroupSetCollidable("NonCollideWithPlayer", "NonCollideWithPlayer", false)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				local plrStatuses = PlayerStatusRegistry.getPlayerStatuses(player)
				plrStatuses:clearAllStatuses()
			end)
		end

		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "NonCollideWithPlayer"
			end
		end
	end)
end)