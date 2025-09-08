--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local PlayerHeadRotation = require(StarterPlayer.StarterPlayerScripts.client.modules.character.PlayerHeadRotation)

local HEAD_ROTATION_REMOTE_CLIENT = TypedRemotes.PlayerHeadRotationClient
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

HEAD_ROTATION_REMOTE_CLIENT.OnClientEvent:Connect(function(player, cameraPos)
	PlayerHeadRotation.addOrUpdatePlayersCameraPos(player, cameraPos)
end)

RunService.RenderStepped:Connect(function(deltaTime)
	PlayerHeadRotation.addOrUpdatePlayersCameraPos(localPlayer, currentCamera.CFrame.Position)
	PlayerHeadRotation.update(deltaTime)
end)
