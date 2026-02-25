--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local IntertitlesScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.IntertitlesScreen)
local CinematicsDirector = require(ReplicatedStorage.shared.cinematic.CinematicsDirector)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local dir: CinematicsDirector.CinematicsDirector?

TypedRemotes.ClientboundCinematicsData.OnClientEvent:Connect(function(data)
	if dir ~= nil then
		dir:destroy()
		dir = nil
	end

	dir = CinematicsDirector.fromData(data)
end)

TypedRemotes.ClientboundCinematicsPlayScene.OnClientEvent:Connect(function(sceneName)
	print(sceneName)
	if dir then
		dir:stop()
		dir:runScene(sceneName, IntertitlesScreen)
	end
end)
