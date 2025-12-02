--!strict

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local CameraManager = require(StarterPlayer.StarterPlayerScripts.client.modules.camera.CameraManager)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local IndicatorsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.hud.indicator.IndicatorsRenderer)
local LoadingScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.LoadingScreen)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)
local LocalPlayer = Players.LocalPlayer

local DEBUG_LOCALIZATION_INIT = false

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

-- So that languages can be loaded properly before anything uses it
local Objectives = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.objectives.Objectives)

RunService.PreRender:Connect(function(deltaTime)
	IndicatorsRenderer.update()
	CameraManager.update(deltaTime)
end)

-- TODO: Tight cuppling bullshit.
local missionConcluded = false

UITextShadow.createTextShadow(LocalPlayer.PlayerGui.MissionConclusion.Root.Title.MissionConclusionTitle)

LocalPlayer.PlayerGui.MissionConclusion.Root.Buttons.RetryButton.MouseButton1Click:Connect(function()
	TypedRemotes.ServerBoundPlayerWantRestart:FireServer()
end)

local debounce = false

LocalPlayer.PlayerGui.MissionConclusion.Root.Buttons.HomeButton.MouseButton1Click:Connect(function()
	if debounce then
		return
	end
	debounce = true
	LoadingScreen.onTeleporting(3, function()
		TypedRemotes.JoinTestingServer:FireServer()
	end)
end)

TypedRemotes.ClientBoundMissionConcluded.OnClientEvent:Connect(function(cameraSocket)
	missionConcluded = true
	CameraManager.takeOverCamera()
	CameraManager.setSocket(cameraSocket)
	CameraManager.startTilting()
	LocalPlayer.PlayerGui.MissionConclusion.Enabled = true
	LocalPlayer.PlayerGui.Objectives.Enabled = false
	LocalPlayer.PlayerGui.Status.Enabled = false
end)

TypedRemotes.ClientBoundMissionStart.OnClientEvent:Connect(function()
	-- How the fuck does this mess work? I don't fucking know.
	-- But it does fix and revert the player's camera back to its original behavior.
	missionConcluded = false
	print(Players.LocalPlayer.Character)
	CameraManager.restoreToDefaultBehavior()
	CameraManager.stopTilting()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CameraSubject = nil
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") 
	end
	CameraManager.restoreToDefaultBehavior()
	task.wait()
	LocalPlayer.PlayerGui.MissionConclusion.Enabled = false
	LocalPlayer.PlayerGui.Objectives.Enabled = true
	LocalPlayer.PlayerGui.Status.Enabled = true
end)

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	print("Character added")
	if not missionConcluded then
		print("Mission not concluded. Restarting camera...")
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		CameraManager.restoreToDefaultBehavior()
	end
end)
