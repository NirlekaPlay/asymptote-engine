--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

TypedRemotes.ClientboundHeadsUpNotif.OnClientEvent:Connect(function(str)
	print(ClientLanguage.getOrDefault(str, str))
end)
