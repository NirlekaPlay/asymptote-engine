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
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)
local LoadingScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.LoadingScreen)
local Transition = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.Transition)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)
local LocalPlayer = Players.LocalPlayer

local DEBUG_LOCALIZATION_INIT = false

-- TODO: Tight cuppling bullshit.
local blurcc = Instance.new("BlurEffect")
blurcc.Size = 25
blurcc.Enabled = false
blurcc.Parent = workspace.CurrentCamera
local missionConcluded = false

local currentMissionData

local missionTitle = LocalPlayer.PlayerGui.MissionConclusion.Root.Title.MissionConclusionTitle
local missionTitleShadow = UITextShadow.createTextShadow(LocalPlayer.PlayerGui.MissionConclusion.Root.Title.MissionConclusionTitle)

local subtitle = LocalPlayer.PlayerGui.MissionConclusion.Root.Subtitle.Subtitle
local subtitleShadow = UITextShadow.createTextShadow(LocalPlayer.PlayerGui.MissionConclusion.Root.Subtitle.Subtitle, nil, 3)

subtitle.Visible = false
subtitleShadow.Visible = false

local retryButton = LocalPlayer.PlayerGui.MissionConclusion.Root.Buttons.RetryButton
local homeButton = LocalPlayer.PlayerGui.MissionConclusion.Root.Buttons.HomeButton

local function updateMissionConclusionScreen(cameraSocket: CameraSocket.CameraSocket, failed: boolean): ()
	missionConcluded = true
	if failed then
		missionTitle.Text = "Mission Failed"
		missionTitleShadow.Text = "Mission Failed"
	else
		missionTitle.Text = "Mission Complete"
		missionTitleShadow.Text = "Mission Complete"
	end
	retryButton.Text = "Replay Mission"
	retryButton.Interactable = true
	homeButton.Interactable = true
	Transition.transition()
	CameraManager.takeOverCamera()
	CameraManager.setSocket(cameraSocket)
	CameraManager.startTilting()
	LocalPlayer.PlayerGui.MissionConclusion.Enabled = true
	LocalPlayer.PlayerGui.Objectives.Enabled = false
	LocalPlayer.PlayerGui.Status.Enabled = false
	LocalPlayer.PlayerGui.Interaction.Enabled = false
	blurcc.Enabled = true
end

TypedRemotes.ClientBoundServerMatchInfo.OnClientEvent:Connect(function(payloadType, data)
	currentMissionData = data
	if data.isConcluded then
		missionConcluded = true
	end
	print("Client receieved match data:")
	for k, v in data :: any do
		print(`'{k}': {v}`)
	end

	if missionConcluded and data then
		updateMissionConclusionScreen(data.cameraSocket, data.isFailed)
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

-- So that languages can be loaded properly before anything uses it
local Objectives = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.objectives.Objectives)

RunService.PreRender:Connect(function(deltaTime)
	IndicatorsRenderer.update()
	CameraManager.update(deltaTime)
end)

retryButton.MouseButton1Click:Connect(function()
	retryButton.Interactable = false
	retryButton.Text = "Replaying Mission..."
	TypedRemotes.ServerBoundPlayerWantRestart:FireServer()
end)

homeButton.MouseButton1Click:Connect(function()
	homeButton.Interactable = false
	homeButton.Text = "Returning to Lobby..."
	LoadingScreen.onTeleporting(3, function()
		TypedRemotes.JoinTestingServer:FireServer()
	end)
end)

TypedRemotes.ClientBoundRemainingRestartPlayers.OnClientEvent:Connect(function(plrsWhoWant, remainingPlrs)
	subtitle.Visible = true
	subtitleShadow.Visible = true

	local str = `{plrsWhoWant}/{remainingPlrs} remaining for replay`
	subtitle.Text = str
	subtitleShadow.Text = str
end)


TypedRemotes.ClientBoundMissionConcluded.OnClientEvent:Connect(updateMissionConclusionScreen)

TypedRemotes.ClientBoundMissionStart.OnClientEvent:Connect(function()
	-- How the fuck does this mess work? I don't fucking know.
	-- But it does fix and revert the player's camera back to its original behavior.
	missionConcluded = false
	Transition.transition()
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
	LocalPlayer.PlayerGui.Interaction.Enabled = true
	blurcc.Enabled = false
	subtitle.Visible = false
	subtitleShadow.Visible = false
end)

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	print("Character added")
	if not missionConcluded then
		print("Mission not concluded. Restarting camera...")
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		CameraManager.restoreToDefaultBehavior()
	end
end)

require(StarterPlayer.StarterPlayerScripts.client.modules.level.Clutters)
