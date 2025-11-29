--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local LoadingScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.LoadingScreen)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local function onTeleportReady()
	TypedRemotes.ServerBoundPlayerTeleportReady:FireServer()
end

TypedRemotes.ClientBoundTeleportReady.OnClientEvent:Connect(function()
	LoadingScreen.onTeleporting(3, onTeleportReady)
end)
