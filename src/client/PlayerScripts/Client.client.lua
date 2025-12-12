--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local CameraManager = require(StarterPlayer.StarterPlayerScripts.client.modules.camera.CameraManager)
local MouseManager = require(StarterPlayer.StarterPlayerScripts.client.modules.input.MouseManager)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local IndicatorsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.hud.indicator.IndicatorsRenderer)
local Spectate = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.Spectate)
local Transition = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.Transition)
local MissionConclusionScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.MissionConclusionScreen)
local LocalPlayer = Players.LocalPlayer

local DEBUG_LOCALIZATION_INIT = false
local DEBUG_MATCH_DATA = false

TypedRemotes.ClientBoundServerMatchInfo.OnClientEvent:Connect(function(payloadType, data)
	if data.isConcluded then
		MissionConclusionScreen.setIsMissionConcluded(true)
	end
	if DEBUG_MATCH_DATA then
		print("Client receieved match data:")
		for k, v in data :: any do
			print(`'{k}': {v}`)
		end
	end

	if MissionConclusionScreen.isConcluded() and data then
		MissionConclusionScreen.updateMissionConclusionScreen(data.cameraSocket, data.isFailed)
	end
end)

-- Localization:

TypedRemotes.ClientBoundLocalizationAppend.OnClientEvent:Connect(function(dict)
	ClientLanguage.appendFromDict(dict)
end)

local success, translator = pcall(function()
	return LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer)
end)

local userLocaleId
if success and translator then
	userLocaleId = translator.LocaleId
	if DEBUG_LOCALIZATION_INIT then
		print("LOCALE")
	end
else
	userLocaleId = "en-us"
	if DEBUG_LOCALIZATION_INIT then
		print("FALLBACK")
	end
end

if DEBUG_LOCALIZATION_INIT then
	print("The user's current locale is: " .. userLocaleId)
end

ClientLanguage.load()

RunService.PreRender:Connect(function(deltaTime)
	MouseManager.update()
	IndicatorsRenderer.update()
	CameraManager.update(deltaTime)
end)

MouseManager.setIconEnabled(false)
MouseManager.setLockEnabled(true)

-- So that languages can be loaded properly before anything uses it
task.spawn(function()
	require(StarterPlayer.StarterPlayerScripts.client.modules.ui.objectives.Objectives)
	require(StarterPlayer.StarterPlayerScripts.client.modules.level.Clutters)
end)

local function handleCharacter(character: Model): ()
	-- Probably should use WaitForChild but I dunno...
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Once(function()
			task.wait(1)
			if #Players:GetPlayers() > 1 and not MissionConclusionScreen.getIsMissionConcluded() then
				Transition.transition()
				MissionConclusionScreen.setOtherGuisEnabled(false)
				Spectate.enableMode()
			end
		end)
	end
end

LocalPlayer.CharacterAdded:Connect(handleCharacter)
if LocalPlayer.Character then
	handleCharacter(LocalPlayer.Character)
end

local mouseToggle = false
ContextActionService:BindAction("ACTION_UNLOCK_MOUSE", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	
	mouseToggle = not mouseToggle

	if mouseToggle then
		MouseManager.addUnuseableMouseOverride("MANUAL_UNLOCK")
	else
		MouseManager.removeUnuseableMouseOverride("MANUAL_UNLOCK")
	end

	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.L)