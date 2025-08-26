local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local PlayerStatusRegistry = require("./player/PlayerStatusRegistry")
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local Level = require(ServerScriptService.server.level.Level)
local Guard = require(ServerScriptService.server.npc.guard.Guard)

local GUARD_TAG_NAME = "Guard"
local GUARD_POSTS_TAG_NAME = "Post"

local guards: { [Model]: Guard.Guard } = {}
local basicGuardPosts: { GuardPost.GuardPost } = {}
local advancedGuardPosts: { GuardPost.GuardPost } = {}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		if post.Parent.Name == "basic" then
			table.insert(basicGuardPosts, newGuardPost)
		else
			table.insert(advancedGuardPosts, newGuardPost)
		end
	end
end

setupGuardPosts()

local function setupGuard(guardChar: Model): ()
	local designatedPosts
	if guardChar:GetAttribute("CanSeeThroughDisguises") then
		designatedPosts = advancedGuardPosts
	else
		designatedPosts = basicGuardPosts
	end
	local newGuard = Guard.new(guardChar, designatedPosts)
	guards[guardChar] = newGuard
end

local function setupGuards()
	for _, guard in ipairs(CollectionService:GetTagged(GUARD_TAG_NAME)) do
		if guard.Parent ~= workspace then
			continue
		end

		setupGuard(guard)
	end
end

setupGuards()

CollectionService:GetInstanceAddedSignal(GUARD_TAG_NAME):Connect(function(guard)
	if guard.Parent ~= workspace then
		local connection: RBXScriptConnection
		connection = guard:GetPropertyChangedSignal("Parent"):Connect(function()
			if guard.Parent == workspace then
				connection:Disconnect()
				setupGuard(guard)
			end
		end)
		return
	end

	setupGuard(guard)
end)

RunService.PostSimulation:Connect(function(deltaTime)
	Level.update(deltaTime)

	-- this frame, is there any listening clients?
	local hasListeningClients = DebugPackets.hasListeningClients(DebugPackets.Packets.DEBUG_BRAIN)
	for model, guard in pairs(guards) do
		if not model.PrimaryPart then
			guards[model] = nil
			model.Parent = nil
			continue
		end

		if not guard:isAlive() then
			setmetatable(guards[model], nil)
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

	-- oh god
	SuspicionManagement.flushBatchToClients()
end)

if not PhysicsService:IsCollisionGroupRegistered("NonCollideWithPlayer") then
	PhysicsService:RegisterCollisionGroup("NonCollideWithPlayer")
end
PhysicsService:CollisionGroupSetCollidable("NonCollideWithPlayer", "NonCollideWithPlayer", false)

local playerConnections: { [Player]: RBXScriptConnection } = {} 

Players.PlayerAdded:Connect(function(player)
	local charConn
	charConn = player.CharacterAppearanceLoaded:Connect(function(character)
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

	playerConnections[player] = charConn
end)

Players.PlayerRemoving:Connect(function(player)
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end)