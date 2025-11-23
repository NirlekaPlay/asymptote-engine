--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local CollectionManager = require(ServerScriptService.server.collection.CollectionManager)
local CollectionTagTypes = require(ServerScriptService.server.collection.CollectionTagTypes)
local Commands = require(ServerScriptService.server.commands.registry.Commands)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)
local Level = require(ServerScriptService.server.world.level.Level)
local DetectionDummy = require(ServerScriptService.server.npc.dummies.DetectionDummy)
local CollisionGroupManager = require(ServerScriptService.server.physics.collision.CollisionGroupManager)
--local Guard = require(ServerScriptService.server.npc.guard.Guard)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local guards: { [Model]: DetectionDummy.DummyAgent } = {}
local nodeGroups: { [string]: { Node.Node } } = {}
local allNodes: { [BasePart]: Node.Node } = {}
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
	local designatedPosts: { Node.Node }

	if guardChar:GetAttribute("CanSeeThroughDisguises") then
		designatedPosts = advancedNodes
	else
		designatedPosts = basicNodes
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

local function getNodes(char: Model): { Node.Node }
	local nodesName = char:GetAttribute("Nodes") :: string
	if not nodeGroups[nodesName] then
		nodeGroups[nodesName] = {}
		local nodesFolder = (workspace.Level.Nodes :: Folder):FindFirstChild(nodesName, true) :: Folder

		local nodesCount = 0
		local stack = { nodesFolder }
		local index = 1
		local seenParts = {}

		while index > 0 do
			local current = stack[index]
			stack[index] = nil
			index -= 1

			if current:IsA("BasePart") and current.Name == "Node" and not seenParts[current] then
				nodesCount += 1
				local newNode
				-- to prevent duplicated nodes
				if allNodes[current] then
					newNode = allNodes[current]
				else
					current.Anchored = true
					current.Transparency = 1
					current.CanCollide = false
					current.CanQuery = false
					current.CanTouch = false
					current.AudioCanCollide = false
					newNode = Node.fromPart(current, false)
					allNodes[current] = newNode
				end
				nodeGroups[nodesName][nodesCount] = newNode
				seenParts[current] = true
			elseif current:IsA("Folder") then
				local children = current:GetChildren()
				for i = #children, 1, -1 do
					index += 1
					stack[index] = children[i]
				end
			end
		end
	end

	return nodeGroups[nodesName]
end

local function setupDummy(dummyChar: Model): ()
	-- this aint a dummy no more now is it?
	local nodes = getNodes(dummyChar)
	local newDummy = DetectionDummy.new(dummyChar, dummyChar:GetAttribute("CharName") :: string?, dummyChar:GetAttribute("Seed") :: number?)
		:setDesignatedPosts(nodes)

	local enforceClassName = dummyChar:GetAttribute("EnforceClass") :: string?
	if dummyChar:GetAttribute("EnforceClass") then
		if not (require)((workspace :: any).Level.MissionSetup).EnforceClass then
			warn("EnforceClass must ATLEAST be an empty table.")
		else
			local enforceClass = (require)((workspace :: any).Level.MissionSetup).EnforceClass[enforceClassName]
			if not enforceClass then
				warn(`Enforce class {enforceClassName} doesnt exist in MissionSetup.`)
			elseif next(enforceClass) ~= nil then
				newDummy:setEnforceClass(enforceClass)
			end
		end
	end

	guards[dummyChar] = newDummy
end

local function onMapTaggedDummies(dummyChar: Model): ()
	if dummyChar.Parent ~= workspace then
		-- And you can't even cast a type as 'the types are unrelated'
		-- so what the fuck do you expect me to do?
		local connection: RBXScriptConnection
		connection = dummyChar:GetPropertyChangedSignal("Parent"):Connect(function()
			if dummyChar.Parent == workspace then
				connection:Disconnect()
				setupDummy(dummyChar)
			end
		end)

		return
	end
	
	setupDummy(dummyChar)
end

local function clearAndDestroyAllNpcs(): ()
	for char, npc in guards do
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end

		--print("Destroying", char)
		char:Destroy()
	end

	table.clear(guards)
end

GlobalStatesHolder.setState("IsStudio", RunService:IsStudio())

CollectionManager.mapTaggedInstances(CollectionTagTypes.NPC_DETECTION_DUMMY, onMapTaggedDummies)

CollectionManager.mapOnTaggedInstancesAdded(CollectionTagTypes.NPC_DETECTION_DUMMY, onMapTaggedDummies)

CollectionManager.mapTaggedInstances(CollectionTagTypes.NPC_GUARD, onMapTaggedGuard)

CollectionManager.mapOnTaggedInstancesAdded(CollectionTagTypes.NPC_GUARD, onMapTaggedGuard)

Level.setDestroyNpcsCallback(clearAndDestroyAllNpcs)
Level.initializeLevel()

-- to prevent race condition bullshit
local playersToRemove: { [number]: true } = {}

local function update(deltaTime: number): ()
	if next(playersToRemove) ~= nil then
		for userId in playersToRemove do
			--warn("REMOVING " .. userId)
			EntityManager.Entities[tostring(userId)] = nil
		end

		table.clear(playersToRemove)
	end

	if Level.isRestarting() then
		return
	end

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
end

RunService.PostSimulation:Connect(update)

--[[local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0
local lastUpdateTime = os.clock()

task.spawn(function()
	while true do
		local deltaTime = os.clock() - lastUpdateTime
		timeAccum += deltaTime

		while timeAccum >= UPDATE_INTERVAL do
			update(UPDATE_INTERVAL)
			timeAccum -= UPDATE_INTERVAL
		end

		lastUpdateTime = os.clock()

		task.wait()
	end
end)]]

CollisionGroupManager.register()

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
	playersToRemove[player.UserId] = true
	--
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end)

Commands.register()