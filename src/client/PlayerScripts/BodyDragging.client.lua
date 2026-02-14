--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local InteractionKeysScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.InteractionKeysScreen)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)

local localPlayer = Players.LocalPlayer

ContextActionService:BindAction("ACTION_STOP_CARRYING", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if not localPlayer.Character then
		return Enum.ContextActionResult.Pass
	end

	local bodyDragObjectValue = localPlayer.Character:FindFirstChild("CurrentDraggingChar")
	if not bodyDragObjectValue or not bodyDragObjectValue:IsA("ObjectValue") or not bodyDragObjectValue.Value then
		return Enum.ContextActionResult.Pass
	end

	TypedRemotes.ServerboundStopBodyDrag:FireServer()

	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.G)

local function showKey(show: boolean): ()
	if show then
		InteractionKeysScreen.showInteractionPair("DROP_BODY", "G", "Drop body")
	else
		InteractionKeysScreen.removeInteractionPair("DROP_BODY")
	end
end

local function processChar(character: Model): ()
	local maid = Maid.new()
	local function onDestroy()
		maid:doCleaning()
		showKey(false)
	end

	maid:giveTask(character.Destroying:Connect(onDestroy))
	maid:giveTask(character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(game) then
			onDestroy()
		end
	end))
	maid:giveTask(character.ChildAdded:Connect(function(child)
		if child:IsA("ObjectValue") and child.Name == "CurrentDraggingChar" then
			maid:giveTask(child.Changed:Connect(function(value)
				showKey(value ~= nil)
			end))

			if child.Value ~= nil then
				showKey(true)
			end
		end
	end))
end

if localPlayer.Character then
	processChar(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(char)
	processChar(char)
end)
