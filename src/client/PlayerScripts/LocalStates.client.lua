--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local LocalStatesHolder = require(StarterPlayer.StarterPlayerScripts.client.modules.states.LocalStatesHolder)
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)

local DEBUG_LOCAL_STATE_CHANGES = false
local LOCAL_STATES = {
	HAS_DISGUISE = "HasDisguise",
	INVENTORY_HAS_FBB = "Inventory_HasFBB",
	INVENTORY_CAN_REFILL_FBB = "Inventory_CanRefillFbb"
}

LocalStatesHolder.setState(LOCAL_STATES.HAS_DISGUISE, false)
LocalStatesHolder.setState(LOCAL_STATES.INVENTORY_HAS_FBB, false)

TypedRemotes.Status.OnClientEvent:Connect(function(playerStatusesMap)
	if playerStatusesMap[PlayerStatusTypes.DISGUISED.name] then
		LocalStatesHolder.setState(LOCAL_STATES.HAS_DISGUISE, true)
	else
		LocalStatesHolder.setState(LOCAL_STATES.HAS_DISGUISE, false)
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

local backpackChildAddedConn: RBXScriptConnection?
local backpackChildRemovedConn: RBXScriptConnection?

local function onCharacterAdded(character: Model): ()
	local backpack = Players.LocalPlayer:WaitForChild("Backpack")
	backpackChildAddedConn = backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			if child.Name ~= "FB Beryl" then
				return
			end

			LocalStatesHolder.setState(LOCAL_STATES.INVENTORY_HAS_FBB, true)
		end
	end)

	backpackChildRemovedConn = backpack.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			if child.Name ~= "FB Beryl" then
				return
			end

			for _, child1 in backpack:GetChildren() do
				if child1.Name == "FB Beryl" then
					return
				end
			end

			if Players.LocalPlayer.Character then
				for _, child1 in (Players.LocalPlayer.Character :: Model):GetChildren() do
					if child1.Name == "FB Beryl" then
						return
					end
				end
			end

			LocalStatesHolder.setState(LOCAL_STATES.INVENTORY_HAS_FBB, false)
		end
	end)
end

Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

Players.LocalPlayer.CharacterRemoving:Connect(function(character)
	if backpackChildAddedConn then
		backpackChildAddedConn:Disconnect()
		backpackChildAddedConn = nil
	end

	if backpackChildRemovedConn then
		backpackChildRemovedConn:Disconnect()
		backpackChildRemovedConn = nil
	end

	LocalStatesHolder.setState(LOCAL_STATES.INVENTORY_HAS_FBB, false)
end)

if Players.LocalPlayer.Character then
	onCharacterAdded(Players.LocalPlayer.Character)
end

if DEBUG_LOCAL_STATE_CHANGES then
	LocalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
		print(`State of '{stateName}' value has changed to {stateValue}`)
	end)
end
