--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local CollectionManager = require(ServerScriptService.server.collection.CollectionManager)
local CollectionTagTypes = require(ServerScriptService.server.collection.CollectionTagTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)
local Level = require(ServerScriptService.server.level.Level)
local DetectionDummy = require(ServerScriptService.server.npc.dummies.DetectionDummy)
local Guard = require(ServerScriptService.server.npc.guard.Guard)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)

local guards: { [Model]: Guard.Guard } = {}
local basicGuardPosts: { GuardPost.GuardPost } = {}
local advancedGuardPosts: { GuardPost.GuardPost } = {}
local playerConnections: { [Player]: RBXScriptConnection } = {}

local SHOW_INITIALIZED_GUARD_CHARACTERS_FULL_NAME = true

local function setupGuard(guardChar: Model): ()
	if SHOW_INITIALIZED_GUARD_CHARACTERS_FULL_NAME then
		-- This is utterly fucking retarded.
		-- (this is actually borrowed from an the onMapTaggedGuard function,
		-- but i will leave this here to show how absurd Luau typechecking
		-- can be.)
		print(((guardChar :: any) :: Model):GetFullName())
	end
	local designatedPosts: { GuardPost.GuardPost }

	if guardChar:GetAttribute("CanSeeThroughDisguises") then
		designatedPosts = advancedGuardPosts
	else
		designatedPosts = basicGuardPosts
	end

	guards[guardChar] = Guard.new(guardChar, designatedPosts)
end

local function onMapTaggedGuard(guardChar: Model): ()
	-- It seems like checking this condition results in the guardChar variable incorrectly refining
	-- to a bullshit type. A table with the property 'Parent'. It should've stayed to be a Model type.
	-- How utterly fucking inconvenient and heavily retarded.
	if guardChar.Parent ~= workspace then
		-- And you can't even cast a type as 'the types are unrelated'
		-- so what the fuck do you expect me to do?
		local connection: RBXScriptConnection
		connection = guardChar:GetPropertyChangedSignal("Parent"):Connect(function()
			if guardChar.Parent == workspace then
				connection:Disconnect()
				setupGuard(guardChar)
			end
		end)

		return
	end

	setupGuard(guardChar)
end

CollectionManager.mapTaggedInstances(CollectionTagTypes.GUARD_POST, function(post: BasePart)
	local newGuardPost = GuardPost.fromPart(post, false)
	
	if (post.Parent :: Instance).Name == "advanced" then
		table.insert(advancedGuardPosts, newGuardPost)
	else
		table.insert(basicGuardPosts, newGuardPost)
	end
end)

CollectionManager.mapTaggedInstances(CollectionTagTypes.NPC_DETECTION_DUMMY, function(dummyChar: Model)
	guards[dummyChar] = DetectionDummy.new(dummyChar)
end)

CollectionManager.mapTaggedInstances(CollectionTagTypes.NPC_GUARD, onMapTaggedGuard)

CollectionManager.mapOnTaggedInstancesAdded(CollectionTagTypes.NPC_GUARD, onMapTaggedGuard)

Level.initializeLevel()

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
	DetectionManagement.flushBatchToClients()
	SuspicionManagement.flushBatchToClients()

	BulletSimulation.update(deltaTime)
end)

if not PhysicsService:IsCollisionGroupRegistered(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER) then
	PhysicsService:RegisterCollisionGroup(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER)
end

PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, false)

Players.PlayerAdded:Connect(function(player)
	-- entity reg here:
	EntityManager.newDynamic("Player", player, tostring(player.UserId))
	--
	local charConn
	charConn = player.CharacterAppearanceLoaded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				local plrStatuses = PlayerStatusRegistry.getPlayerStatusHolder(player)
				plrStatuses:clearAllStatuses()
			end)
		end

		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = CollisionGroupTypes.PLAYER
			end
		end
	end)

	playerConnections[player] = charConn
end)

Players.PlayerRemoving:Connect(function(player)
	-- entity reg here:
	EntityManager.Entities[tostring(player.UserId)] = nil
	--
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end)