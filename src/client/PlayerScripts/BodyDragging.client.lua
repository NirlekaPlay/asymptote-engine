--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

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
end, false, Enum.KeyCode.F)