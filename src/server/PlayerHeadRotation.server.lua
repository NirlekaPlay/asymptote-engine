--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local PlayerHeadRotationClient = TypedRemotes.PlayerHeadRotationClient

TypedRemotes.PlayerHeadRotationServer.OnServerEvent:Connect(function(player, cameraPos)
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == player then
			continue
		end

		PlayerHeadRotationClient:FireClient(otherPlayer, player, cameraPos)
	end
end)