--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local IntertitlesScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.IntertitlesScreen)
local CinematicsDirector = require(ReplicatedStorage.shared.cinematic.CinematicsDirector)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local dir: CinematicsDirector.CinematicsDirector?
local cacheData: any = nil

TypedRemotes.ClientboundCinematicsData.OnClientEvent:Connect(function(data)
	if dir ~= nil then
		dir:destroy()
		dir = nil
	end

	dir = CinematicsDirector.fromData(data)
	cacheData = data
end)

TypedRemotes.ClientboundCinematicsPlayScene.OnClientEvent:Connect(function(sceneName)
	print(sceneName)
	if dir then
		dir:stop()
		dir:runScene(sceneName, IntertitlesScreen)
	elseif dir == nil and cacheData then
		dir = CinematicsDirector.fromData(cacheData);
		(dir :: any):runScene(sceneName, IntertitlesScreen)
	end
end)

local t = {}

function t.interrupt(): ()
	if dir ~= nil then
		dir:destroy()
		dir = nil
		IntertitlesScreen.fadeOut()
	end
end

return t