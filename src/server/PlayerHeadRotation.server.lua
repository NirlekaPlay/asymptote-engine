--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)

TypedRemotes.PlayerHeadRotationServer.OnServerEvent:Connect(function(player, cameraPos)
	if not player.Character then return end

	--local torso = player.Character:FindFirstChild("Torso") :: BasePart
	--local neck = torso:FindFirstChild("Neck") :: Motor6D
	--neck.C0 = cframe

	TypedRemotes.PlayerHeadRotationClient:FireAllClients(player, cameraPos)
end)
