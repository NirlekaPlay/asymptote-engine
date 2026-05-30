--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local DebugPacketTypes = require(ReplicatedStorage.shared.network.DebugPacketTypes)
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local Commands = require(ServerScriptService.server.commands.registry.Commands)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)
local CollisionGroupManager = require(ServerScriptService.server.physics.collision.CollisionGroupManager)
local Teleportation = require(ServerScriptService.server.teleportation.Teleportation)
local ItemService = require(ReplicatedStorage.shared.world.item.ItemService)
local NewLevel = require(ServerScriptService.server.world.level.NewLevel)
local Clutter = require(ServerScriptService.server.world.level.scene.props.Clutter)

local level = NewLevel.new()

local function onPostSimulation(deltaTime: number): ()
	debug.profilebegin("update_postSimulation")
	local hasListeningClients = DebugPackets.hasListeningClients(DebugPacketTypes.DEBUG_BRAIN)
	level:update(deltaTime)
	
	if hasListeningClients then
		DebugPackets.flushBrainDumpsToListeningClients()
	end

	BulletSimulation.update(deltaTime)
	debug.profileend()
end

--

local function onPlayerAdded(player: Player): ()
	task.spawn(Teleportation.onPlayerAdded, player)
end

local function onPlayerRemoving(player: Player): ()
	task.spawn(Teleportation.onPlayerRemoving, player)
end

--

local function initialize(): ()
	CollisionGroupManager.register()
	ItemService.register()
	Commands.register(level :: any)
	Clutter.initialize()
end

initialize()

level:loadScene("test_place")

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
RunService.PostSimulation:Connect(onPostSimulation)
TypedRemotes.SubscribeDebugDump.OnServerEvent:Connect(DebugPackets.onReceiveSubscription)