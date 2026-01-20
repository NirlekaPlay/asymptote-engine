--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local DEBUG_PRINT_REPLICATION_TRAFFIC = false

GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
	TypedRemotes.ClientBoundReplicateIndividualGlobalStates:FireAllClients(stateName, stateValue)
end)

TypedRemotes.ServerBoundGlobalStatesReplicateRequest.OnServerEvent:Connect(function(player)
	if DEBUG_PRINT_REPLICATION_TRAFFIC then
		print("Replication request received from", player, "sending all global states...")
	end
	TypedRemotes.ClientBoundReplicateAllGlobalStates:FireClient(player, GlobalStatesHolder.getAllStatesReference())
end)

Players.PlayerAdded:Connect(function(player)
	if DEBUG_PRINT_REPLICATION_TRAFFIC then
		print(`Player '{player}' has been added. Replicating global states...`)
	end
	TypedRemotes.ClientBoundReplicateAllGlobalStates:FireClient(player, GlobalStatesHolder.getAllStatesReference())
end)
