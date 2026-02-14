--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local root = Players.LocalPlayer.PlayerScripts

local PlayerModule = require(root.client.PlayerModule)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local controls = PlayerModule:GetControls()

TypedRemotes.ClientboundSetPlayerModuleDisability.OnClientEvent:Connect(function(enable)
	if not controls then
		controls = PlayerModule:GetControls()
	end
	if enable then
		controls:Enable(true)
	else
		controls:Disable()
	end
end)
