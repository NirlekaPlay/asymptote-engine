--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)
local CameraManager = require(StarterPlayer.StarterPlayerScripts.client.modules.camera.CameraManager)
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)
local MouseManager = require(StarterPlayer.StarterPlayerScripts.client.modules.input.MouseManager)
local LoadingScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.LoadingScreen)
local Spectate = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.Spectate)
local Transition = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.Transition)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UITextShadow)
local DialogueController = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.dialogue.DialogueController)
local HealthSaturationScreen = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.screens.HealthSaturationScreen)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local MissionConclusionScreenGui = ReplicatedStorage.shared.assets.gui.MissionConclusion

local BLUR_CC_NAME = "MissionConclusionBlur"

-- There might be a better way but we'll do this for now.
-- Since these ScreenGuis may or may not be present due to
-- player character not loaded.
-- Better than stalling and using WaitForChild.
local DISABLE_SCREEN_GUIS_NAME = {
	["Objectives"] = true,
	["Status"] = true,
	["Interaction"] = true,
	["BubbleChat"] = true,
	["Indicators"] = true
} :: { [string]: true }

local missionConcluded = false

--[=[
	@class MissionConclusionScreen
]=]
local MissionConclusionScreen = {}

function MissionConclusionScreen.setIsMissionConcluded(concluded: boolean): ()
	missionConcluded = concluded
end

function MissionConclusionScreen.getIsMissionConcluded(): boolean
	return missionConcluded
end

function MissionConclusionScreen.isConcluded(): boolean
	return missionConcluded
end

function MissionConclusionScreen.onClickHomeButton(): ()
	local missionConclusionGui = MissionConclusionScreen.getScreenGui()
	local homeButton = missionConclusionGui.Root.Buttons.HomeButton
	homeButton.Interactable = false
	homeButton.Text = "Returning to Lobby..."
	LoadingScreen.onTeleporting(0, function()
		TypedRemotes.JoinTestingServer:FireServer()
	end)
end

function MissionConclusionScreen.onClickRetryButton(): ()
	local missionConclusionGui = MissionConclusionScreen.getScreenGui()
	local retryButton = missionConclusionGui.Root.Buttons.RetryButton
	retryButton.Interactable = false
	retryButton.Text = "Replaying Mission..."
	TypedRemotes.ServerBoundPlayerWantRestart:FireServer()
end

function MissionConclusionScreen.onReceiveReplayData(plrsWhoWant: number, remainingPlrs: number): ()
	local gui = MissionConclusionScreen.getScreenGui()
	local subtitleFrame = gui.Root.Subtitle
	local subtitle = gui.Root.Subtitle.Subtitle
	local subtitleShadow = (gui.Root.Subtitle :: any).Subtitle_Shadow :: TextLabel
	subtitleFrame.Visible = true
	local str = `{plrsWhoWant}/{remainingPlrs} remaining for replay`
	subtitle.Text = str
	subtitleShadow.Text = str
end

function MissionConclusionScreen.onMissionStart(): ()
	-- How the fuck does this mess work? I don't fucking know.
	-- But it does fix and revert the player's camera back to its original behavior.
	missionConcluded = false

	local blurcc = MissionConclusionScreen.getBlurCc()
	local missionConclusionGui = MissionConclusionScreen.getScreenGui()
	local subtitleFrame = missionConclusionGui.Root.Subtitle
	
	Transition.transition()
	HealthSaturationScreen.enable()
	Spectate.disableMode()
	CameraManager.restoreToDefaultBehavior()
	CameraManager.stopTilting()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CameraSubject = nil
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		workspace.CurrentCamera.CameraSubject = (Players.LocalPlayer.Character :: Model)
			:FindFirstChildOfClass("Humanoid") 
	end
	CameraManager.restoreToDefaultBehavior()
	task.wait()
	missionConclusionGui.Enabled = false
	MissionConclusionScreen.setOtherGuisEnabled(true)
	blurcc.Enabled = false
	subtitleFrame.Visible = false
	CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, true)

	MouseManager.setIconEnabled(false)
	MouseManager.setLockEnabled(true)
end

function MissionConclusionScreen.updateMissionConclusionScreen(
	cameraSocket: CameraSocket.CameraSocket, failed: boolean
): ()
	DialogueController.forceClose()

	local blurcc = MissionConclusionScreen.getBlurCc()
	local missionConclusionGui = MissionConclusionScreen.getScreenGui()
	local retryButton = missionConclusionGui.Root.Buttons.RetryButton
	local homeButton = missionConclusionGui.Root.Buttons.HomeButton
	local missionTitle = missionConclusionGui.Root.Title.MissionConclusionTitle
	local missionTitleShadow = (missionConclusionGui.Root.Title :: any).MissionConclusionTitle_Shadow :: TextLabel

	missionConcluded = true
	if failed then
		missionTitle.Text = "Mission Failed"
		missionTitleShadow.Text = "Mission Failed"
	else
		missionTitle.Text = "Mission Complete"
		missionTitleShadow.Text = "Mission Complete"
	end
	-- TODO: This is bad. Choose a different logic...
	if ReplicatedStorage:FindFirstChild("IsLobby") and ReplicatedStorage:FindFirstChild("IsLobby").Value then
		homeButton.Visible = false
	else
		homeButton.Visible = true
	end
	retryButton.Text = "Replay Mission"
	retryButton.Interactable = true
	homeButton.Text = "Return to Lobby"
	homeButton.Interactable = true
	Transition.transition()
	HealthSaturationScreen.disable()
	Spectate.disableMode()
	CameraManager.takeOverCamera()
	CameraManager.setSocket(cameraSocket)
	CameraManager.startTilting()
	missionConclusionGui.Enabled = true
	MissionConclusionScreen.setOtherGuisEnabled(false)
	blurcc.Enabled = true
	CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, false)

	MouseManager.setIconEnabled(true)
	MouseManager.setLockEnabled(false)
end

function MissionConclusionScreen.setOtherGuisEnabled(enabled: boolean): ()
	for name in DISABLE_SCREEN_GUIS_NAME do
		local found = PlayerGui:FindFirstChild(name)
		if found and found:IsA("ScreenGui") then
			found.Enabled = enabled
		end
	end
end

function MissionConclusionScreen.getBlurCc(): BlurEffect
	local existing = workspace.CurrentCamera:FindFirstChild(BLUR_CC_NAME)
	if existing and existing:IsA("BlurEffect") then
		return existing
	end

	local blurcc = Instance.new("BlurEffect")
	blurcc.Size = 25
	blurcc.Enabled = false
	blurcc.Name = BLUR_CC_NAME
	blurcc.Parent = workspace.CurrentCamera

	return blurcc
end

function MissionConclusionScreen.getScreenGui(): typeof(MissionConclusionScreenGui)
	local existing = PlayerGui:FindFirstChild("MissionConclusion") :: any
	if not existing then
		local cloned = MissionConclusionScreenGui:Clone()
		cloned.Enabled = false
		cloned.Parent = PlayerGui

		local missionTitle = cloned.Root.Title.MissionConclusionTitle
		local _missionTitleShadow = UITextShadow.createTextShadow(missionTitle)

		local subtitleFrame = cloned.Root.Subtitle
		local subtitle = cloned.Root.Subtitle.Subtitle
		local subtitleShadow = UITextShadow.createTextShadow(cloned.Root.Subtitle.Subtitle, nil, 3)

		subtitleFrame.Visible = false
		subtitle.Visible = true
		subtitleShadow.Visible = true

		return cloned
	end

	return existing
end

TypedRemotes.ClientBoundMissionStart.OnClientEvent:Connect(MissionConclusionScreen.onMissionStart)
TypedRemotes.ClientBoundMissionConcluded.OnClientEvent:Connect(MissionConclusionScreen.updateMissionConclusionScreen)
TypedRemotes.ClientBoundRemainingRestartPlayers.OnClientEvent:Connect(MissionConclusionScreen.onReceiveReplayData)

local missionConclusionGui = MissionConclusionScreen.getScreenGui()

missionConclusionGui.Root.Buttons.RetryButton.MouseButton1Click:Connect(MissionConclusionScreen.onClickRetryButton)
missionConclusionGui.Root.Buttons.HomeButton.MouseButton1Click:Connect(MissionConclusionScreen.onClickHomeButton)

return MissionConclusionScreen