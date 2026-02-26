--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local IntertitlesScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.IntertitlesScreen)
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)
local CinematicsDirector = require(ReplicatedStorage.shared.cinematic.CinematicsDirector)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local dir: CinematicsDirector.CinematicsDirector?
local cacheData: any = nil

local function onCinematicSceneFinished(sceneName: string?): ()
	if not sceneName or sceneName == "intro" then
		TypedRemotes.ServerboundCinematicsPlayerIntroDone:FireServer()
		CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, true)
	end
end

local function newCinematicsDirector<T>(data: T): CinematicsDirector.CinematicsDirector
	return CinematicsDirector.fromData(data, onCinematicSceneFinished)
end

TypedRemotes.ClientboundCinematicsData.OnClientEvent:Connect(function(data)
	if dir ~= nil then
		dir:destroy()
		dir = nil
	end

	dir = newCinematicsDirector(data)
	cacheData = data
end)

TypedRemotes.ClientboundCinematicsPlayScene.OnClientEvent:Connect(function(sceneName)
	print(sceneName)
	if dir then
		dir:stop()
		dir:runScene(sceneName, IntertitlesScreen)
	elseif dir == nil and cacheData then
		dir = newCinematicsDirector(cacheData);
		(dir :: any):runScene(sceneName, IntertitlesScreen)
	end
end)

--[=[
	@class ClientCinematics
]=]
local ClientCinematics = {}

function ClientCinematics.hasData(): boolean
	return cacheData ~= nil
end

function ClientCinematics.interrupt(): ()
	if dir ~= nil then
		dir:destroy()
		dir = nil
		IntertitlesScreen.fadeOut()
	end
end

function ClientCinematics.onSkipKeyPressed(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	ClientCinematics.interrupt()

	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("ACTION_CINEMATIC_SCENE_SKIP", ClientCinematics.onSkipKeyPressed, false, Enum.KeyCode.Y)

return ClientCinematics