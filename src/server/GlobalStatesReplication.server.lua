--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
	TypedRemotes.ClientBoundReplicateIndividualGlobalStates:FireAllClients(stateName, stateValue)
end)

TypedRemotes.ServerBoundGlobalStatesReplicateRequest.OnServerEvent:Connect(function(player)
	print("Replication request received from", player, "sending all global states...")
	TypedRemotes.ClientBoundReplicateAllGlobalStates:FireClient(player, GlobalStatesHolder.getAllStatesReference())
end)

Players.PlayerAdded:Connect(function(player)
	print(`Player '{player}' has been added. Replicating global states...`)
	TypedRemotes.ClientBoundReplicateAllGlobalStates:FireClient(player, GlobalStatesHolder.getAllStatesReference())
end)
