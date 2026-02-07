--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugPacketTypes = require(ReplicatedStorage.shared.network.DebugPacketTypes)
local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ItemService = require(ReplicatedStorage.shared.world.item.ItemService)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local CollectionManager = require(ServerScriptService.server.collection.CollectionManager)
local CollectionTagTypes = require(ServerScriptService.server.collection.CollectionTagTypes)
local Commands = require(ServerScriptService.server.commands.registry.Commands)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)
local Level = require(ServerScriptService.server.world.level.Level)
local DetectionDummy = require(ServerScriptService.server.npc.dummies.DetectionDummy)
local CollisionGroupManager = require(ServerScriptService.server.physics.collision.CollisionGroupManager)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local guards: { [Model]: DetectionDummy.DummyAgent } = {}
local nodeGroups: { [string]: { Node.Node } } = {}
local allNodes: { [BasePart]: Node.Node } = {}
local playerConnections: { [Player]: RBXScriptConnection } = {}

local function nullifyNodes(): ()
	nodeGroups = {}
	for part, node in allNodes do
		if part then
			part:Destroy()
		end
	end

	allNodes = {}
end

local function getNodes(char: Model): { Node.Node }
	local nodesName = char:GetAttribute("Nodes") :: string

	if not nodeGroups[nodesName] then
		nodeGroups[nodesName] = {}
		
		-- Find the root folder for this group (e.g., "LowerOfficePatrol")
		local nodesFolder = Level:getServerLevelInstancesAccessor():getNodesFolder():FindFirstChild(nodesName, true) :: Folder
		if not nodesFolder then return {} end

		local nodesCount = 0
		local stack = { nodesFolder }
		local index = 1
		
		-- We use this to ensure that if a node is physically duplicated 
		-- inside the SAME folder tree, we don't add it twice to THIS group.
		local seenInThisGroup = {}

		while index > 0 do
			local current = stack[index]
			stack[index] = nil
			index -= 1

			if current:IsA("BasePart") and current.Name == "Node" then
				if not seenInThisGroup[current] then
					nodesCount += 1
					
					local newNode
					-- Check the GLOBAL cache to ensure ONE reference
					if allNodes[current] then
						newNode = allNodes[current]
					else
						current.Anchored = true
						current.Transparency = 1
						current.CanCollide = false
						current.CanQuery = false
						current.CanTouch = false
						
						newNode = Node.fromPart(current, true)
						allNodes[current] = newNode
					end
					
					nodeGroups[nodesName][nodesCount] = newNode
					seenInThisGroup[current] = true
				end
			elseif current:IsA("Folder") or current:IsA("Model") then
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
	local newDummy = DetectionDummy.new(Level, dummyChar, dummyChar:GetAttribute("CharName") :: string?, dummyChar:GetAttribute("Seed") :: number?)
		:setDesignatedPosts(nodes)

	local enforceClassName = dummyChar:GetAttribute("EnforceClass") :: string?
	if enforceClassName then
		local enforceClass = Level:getServerLevelInstancesAccessor():getMissionSetup():getEnforceClass(enforceClassName)
		if not enforceClass then
			warn(`Enforce class {enforceClassName} doesnt exist in MissionSetup.`)
		elseif next(enforceClass) ~= nil then
			newDummy:setEnforceClass(enforceClass)
		end
	end

	local charName = newDummy:getCharacterName()
	local dummyUuid = newDummy:getUuid()
	local humanoid = ((dummyChar :: any).Humanoid :: Humanoid)

	local diedConn = humanoid.Died:Once(function()
		if not dummyChar or dummyChar.Parent == nil then
			return
		end

		EntityManager.newDynamic("DeadBody", dummyChar, dummyUuid)
		humanoid.DisplayName = charName
	end)

	dummyChar.Destroying:Once(function()
		if diedConn then
			diedConn:Disconnect()
			diedConn = nil :: any
		end

		EntityManager.Entities[dummyUuid] = nil
	end)

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

local function uponLevelClearCallback(): ()
	nullifyNodes()
end

GlobalStatesHolder.setState("IsStudio", RunService:IsStudio())

CollectionManager.mapTaggedInstances(CollectionTagTypes.NPC_DETECTION_DUMMY, onMapTaggedDummies)

CollectionManager.mapOnTaggedInstancesAdded(CollectionTagTypes.NPC_DETECTION_DUMMY, onMapTaggedDummies)

ItemService.register()
Level.setDestroyNpcsCallback(clearAndDestroyAllNpcs)
Level.setUponLevelClearCallback(uponLevelClearCallback)
pcall(function()
	Level.initializeLevel()
end)

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

	if Level.canUpdateLevel() then
		Level.update(deltaTime)
	end

	-- this frame, is there any listening clients?
	local hasListeningClients = DebugPackets.hasListeningClients(DebugPacketTypes.DEBUG_BRAIN)
	for model, guard in pairs(guards) do
		if not model.PrimaryPart then
			guards[model] = nil
			model.Parent = nil
			continue
		end

		if not model:IsDescendantOf(workspace) or not guard:isAlive() then
			guards[model] = nil
			task.spawn(function()
				task.wait(1) -- wait for a while so the died connections can run properly.
				setmetatable(guard, nil)
			end)
		end

		if Level.canUpdateLevel() then
			guard:update(deltaTime)
		end
		if hasListeningClients then
			DebugPackets.queueDataToBatch(DebugPacketTypes.DEBUG_BRAIN, DebugPackets.createBrainDump(guard))
		end
	end

	if hasListeningClients then
		DebugPackets.flushBrainDumpsToListeningClients()
	end

	-- oh god
	DetectionManagement.flushBatchToClients()

	if Level.canUpdateLevel() then
		BulletSimulation.update(deltaTime)
	end
end

RunService.PostSimulation:Connect(update)

CollisionGroupManager.register()

-- To prevent streaming bullshit.
-- This fixes players who joined and don't have a character yet.
-- Leading to empty voids.
local replicationFocusPart = Instance.new("Part")
replicationFocusPart.Anchored = true
replicationFocusPart.CanCollide = false
replicationFocusPart.CanQuery = false
replicationFocusPart.CanTouch = false
replicationFocusPart.AudioCanCollide = false
replicationFocusPart.Transparency = 1
replicationFocusPart.Position = Vector3.zero
replicationFocusPart.Name = "ReplicationFocus"
replicationFocusPart.Parent = workspace

local function proccessPlayer(player: Player): ()
	player.ReplicationFocus = replicationFocusPart
	Level.onPlayerJoined(player)
	-- Localization:
	local localizedStrings = Level:getServerLevelInstancesAccessor():getMissionSetup().localizedStrings
	if localizedStrings and next(localizedStrings) ~= nil then
		TypedRemotes.ClientBoundLocalizationAppend:FireClient(player, localizedStrings)
	end
	-- entity reg here:
	EntityManager.newDynamic("Player", player, tostring(player.UserId))

	--
	local charConn
	charConn = player.CharacterAppearanceLoaded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				Level.onPlayerDied(player)
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
end

Players.PlayerAdded:Connect(proccessPlayer)

for _, player in Players:GetPlayers() do
	if EntityManager.Entities[tostring(player.UserId)] == nil then
		proccessPlayer(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	Level.onPlayerRemoving(player)
	-- entity reg here:
	playersToRemove[player.UserId] = true
	--
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end)

Commands.register()

Level.startMission()

-- Derailer

local GROUP_ID = 34035167
local GROUP_ALLOWED_ROLE_NAMES = {
	["Tester"] = true,
	["Developer"] = true,
	["Director"] = true
}

local function checkCanI(player: Player): boolean
	-- isnt this fucking deprecated?
	-- IT FUCKING IS SO WHY TF IS IT NOT FLAGGED
	-- YOU HAVE ONE FUCKING JOB
	if not player:IsInGroupAsync(GROUP_ID) then
		return true
	end

	return GROUP_ALLOWED_ROLE_NAMES[player:GetRoleInGroupAsync(GROUP_ID)] -- ALSO FUCKING DEPRECATED
end

TypedRemotes.ServerBoundClientForeignChatted.OnServerEvent:Connect(function(transmitter, msg)
	for _, player in Players:GetPlayers() do
		if player == transmitter then
			continue
		end
		if not checkCanI(player) then
			continue
		end
		TypedRemotes.ClientBoundForeignChatMessage:FireClient(player, transmitter, msg)
	end
end)

TypedRemotes.SubscribeDebugDump.OnServerEvent:Connect(DebugPackets.onReceiveSubscription)