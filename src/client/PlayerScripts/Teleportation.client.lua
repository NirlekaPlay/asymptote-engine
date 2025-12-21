--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local LoadingScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.LoadingScreen)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local function onTeleportReady()
	TypedRemotes.ServerBoundPlayerTeleportReady:FireServer()
end

TypedRemotes.ClientBoundTeleportReady.OnClientEvent:Connect(function()
	LoadingScreen.onTeleporting(0, onTeleportReady)
end)

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage, placeId, teleportOptions)
	print("Teleportation failed:", player, teleportResult, errorMessage, placeId, teleportOptions)
	LoadingScreen.revert()
end)
