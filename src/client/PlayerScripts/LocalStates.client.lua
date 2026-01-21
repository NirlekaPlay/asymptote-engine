--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local LocalStatesHolder = require(StarterPlayer.StarterPlayerScripts.client.modules.states.LocalStatesHolder)
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)

local DEBUG_LOCAL_STATE_CHANGES = false
local DEBUG_PRINT_REPLICATION_TRAFFIC = false
local LOCAL_STATES = {
	HAS_DISGUISE = "HasDisguise",
	INVENTORY_HAS_FBB = "Inventory_HasFBB",
	INVENTORY_CAN_REFILL_FBB = "Inventory_CanRefillFbb",
	CURRENT_PLAYER_DISGUISE = "CurrentPlayerDisguise"
}

LocalStatesHolder.setState(LOCAL_STATES.CURRENT_PLAYER_DISGUISE, nil)
LocalStatesHolder.setState(LOCAL_STATES.INVENTORY_HAS_FBB, false)

TypedRemotes.ClientBoundReplicateIndividualGlobalStates.OnClientEvent:Connect(function(stateName, stateValue)
	ReplicatedGlobalStates.setState(stateName, stateValue)
end)

TypedRemotes.ClientBoundReplicateAllGlobalStates.OnClientEvent:Connect(function(states)
	if DEBUG_PRINT_REPLICATION_TRAFFIC then
		print("Global states replication from server received.")
	end
	for stateName, stateValue in states do
		ReplicatedGlobalStates.setState(stateName, stateValue)
	end
end)

TypedRemotes.ServerBoundGlobalStatesReplicateRequest:FireServer()
if DEBUG_PRINT_REPLICATION_TRAFFIC then
	print("Client: Request to give all global states in the server fired.")
end

local backpackChildAddedConn: RBXScriptConnection?
local backpackChildRemovedConn: RBXScriptConnection?
local charAttributesChangedConn: RBXScriptConnection?

local function onCharacterAdded(character: Model): ()
	LocalStatesHolder.setState(LOCAL_STATES.CURRENT_PLAYER_DISGUISE, nil)

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

	if not charAttributesChangedConn then
		charAttributesChangedConn = character:GetAttributeChangedSignal(LOCAL_STATES.CURRENT_PLAYER_DISGUISE):Connect(function()
			LocalStatesHolder.setState(LOCAL_STATES.CURRENT_PLAYER_DISGUISE, character:GetAttribute(LOCAL_STATES.CURRENT_PLAYER_DISGUISE))
		end)
	end
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

	if charAttributesChangedConn then
		charAttributesChangedConn:Disconnect()
		charAttributesChangedConn = nil
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
