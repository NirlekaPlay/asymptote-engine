--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local LocalStatesHolder = require(StarterPlayer.StarterPlayerScripts.client.modules.states.LocalStatesHolder)
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)

LocalStatesHolder.setState("HasDisguise", false)

TypedRemotes.Status.OnClientEvent:Connect(function(playerStatusesMap)
	if playerStatusesMap[PlayerStatusTypes.DISGUISED.name] then
		LocalStatesHolder.setState("HasDisguise", true)
	else
		LocalStatesHolder.setState("HasDisguise", false)
	end
end)

TypedRemotes.ClientBoundReplicateIndividualGlobalStates.OnClientEvent:Connect(function(stateName, stateValue)
	ReplicatedGlobalStates.setState(stateName, stateValue)
end)

TypedRemotes.ClientBoundReplicateAllGlobalStates.OnClientEvent:Connect(function(states)
	print("Global states replication from server received.")
	for stateName, stateValue in states do
		ReplicatedGlobalStates.setState(stateName, stateValue)
	end
end)

TypedRemotes.ServerBoundGlobalStatesReplicateRequest:FireServer()
print("Client: Request to give all global states in the server fired.")