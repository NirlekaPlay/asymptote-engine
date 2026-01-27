--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ClientboundPlayerHeadRotation = TypedRemotes.ClientboundPlayerHeadRotation

TypedRemotes.ServerboundPlayerHeadRotation.OnServerEvent:Connect(function(player, cameraPos)
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == player then
			continue
		end

		ClientboundPlayerHeadRotation:FireClient(otherPlayer, player, cameraPos)
	end
end)