--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local LoadingScreen = require(script.Parent.LoadingScreen)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)

local ENGINE_VERSION_SCREEN_GUI_NAME = "EngineVersion"
local ENGINE_VERSION_STRING_VALUE_NAME = "Version"
local ENGINE_IS_EXPERIMENTAL_BOOL_VALUE = "IsExperimental"
local ENGINE_DEFAULT_HEAD_TEXT = "AsymptoteEngine: Demo"
local ENGINE_IS_EXPERIMENTAL_HEAD_TEXT = "AsymptoteEngine Experimental Server"
local IS_LOBBY_BOOL_VALUE = "IsLobby"
local MIN_TIME_TO_SHOW_JOIN_TESTING_SERVER_BUTTON = 3
local ERR_MSG_NO_VERSION_STRING_VALUE = "ERR_VERSION_STRING_VALUE_NOT_FOUND"

local localPlayer = Players.LocalPlayer
local isStudio = RunService:IsStudio()
local playerGui = localPlayer.PlayerGui
local serverVersionStringValue = ReplicatedStorage:FindFirstChild(ENGINE_VERSION_STRING_VALUE_NAME) :: StringValue?
local serverIsExperimentalBoolValue = ReplicatedStorage:FindFirstChild(ENGINE_IS_EXPERIMENTAL_BOOL_VALUE) :: BoolValue?
local serverIsLobbyBoolValue = ReplicatedStorage:FindFirstChild(IS_LOBBY_BOOL_VALUE) :: BoolValue?
local showJoinServerButtonTimer = 0
local joinServerButton: TextButton? = nil
local joinServerButtonRunConnection: RBXScriptConnection? = nil

do
	if not serverVersionStringValue then
		warn(`'{ENGINE_VERSION_STRING_VALUE_NAME}' StringValue not found in ReplicatedStorage.`)
	end

	if not serverIsExperimentalBoolValue then
		warn(`'{ENGINE_IS_EXPERIMENTAL_BOOL_VALUE}' BoolValue not found in ReplicatedStorage.`)
	end

	if not serverIsLobbyBoolValue then
		warn(`'{IS_LOBBY_BOOL_VALUE}' BoolValue not found in ReplicatedStorage.`)
	end
end

--[=[
	@class EngineVersionGui
]=]
local EngineVersionGui = {}

function EngineVersionGui.setEngineAndVersionTexts(headText: TextLabel, versionText: TextLabel): ()
	headText.Text = (serverIsExperimentalBoolValue and serverIsExperimentalBoolValue.Value ~= false)
		and ENGINE_IS_EXPERIMENTAL_HEAD_TEXT or ENGINE_DEFAULT_HEAD_TEXT

	versionText.Text = serverVersionStringValue
		and serverVersionStringValue.Value or ERR_MSG_NO_VERSION_STRING_VALUE
	
	local headTextShadow = headText:FindFirstChild(headText.Name .. "_Shadow") :: TextLabel?
	if not headTextShadow then
		headTextShadow = UITextShadow.createTextShadow(headText, nil, 2, nil, 0)
		headTextShadow.Parent = headText
	else
		UITextShadow.updateShadowProperties(headText, headTextShadow)
	end

	local versionTextShadow = versionText:FindFirstChild(versionText.Name .. "_Shadow") :: TextLabel?
	if not versionTextShadow then
		versionTextShadow = UITextShadow.createTextShadow(versionText, nil, 2, nil, 0)
		versionTextShadow.Parent = versionText
	else
		UITextShadow.updateShadowProperties(versionText, versionTextShadow)
	end
end

function EngineVersionGui.createNewJoinServerButton(safeAreaFrame: Frame): TextButton?
	if not (serverIsLobbyBoolValue and serverIsLobbyBoolValue.Value == true) then
		return nil
	end

	local newTextButton = Instance.new("TextButton")
	newTextButton.Name = "JoinServerButton"
	newTextButton.AutomaticSize = Enum.AutomaticSize.X
	newTextButton.BackgroundColor3 = Color3.new(0, 0, 0)
	newTextButton.BackgroundTransparency = 0.5
	newTextButton.Size = UDim2.fromOffset(170, 31)
	newTextButton.FontFace = Font.fromName("Zekton")
	newTextButton.TextColor3 = Color3.new(1, 1, 1)
	newTextButton.TextSize = 19
	newTextButton.Visible = false

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 5)
	uiCorner.Parent = newTextButton

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.Parent = newTextButton

	newTextButton.Parent = safeAreaFrame

	return newTextButton
end

function EngineVersionGui.setupJoinServerButtonIfValid(versionTextFrame: Frame): ()
	if not joinServerButton then
		return
	end

	if joinServerButtonRunConnection then
		joinServerButtonRunConnection:Disconnect()
	end

	local isExperimental = (serverIsExperimentalBoolValue and serverIsExperimentalBoolValue.Value ~= false)
	if isExperimental then
		joinServerButton.Visible = true
		joinServerButton.Text = "Leave Testing Server"
		joinServerButton.Activated:Once(EngineVersionGui.onJoinServerButtonTriggered)
	else
		joinServerButton.Visible = false
		joinServerButton.Text = "Join Testing Server"
	end

	joinServerButtonRunConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if versionTextFrame.GuiState ~= Enum.GuiState.Press then
			return
		end

		showJoinServerButtonTimer += deltaTime

		if showJoinServerButtonTimer >= MIN_TIME_TO_SHOW_JOIN_TESTING_SERVER_BUTTON then
			if joinServerButtonRunConnection then
				joinServerButtonRunConnection:Disconnect()
				joinServerButtonRunConnection = nil
			end

			if joinServerButton then
				joinServerButton.Visible = true
				joinServerButton.Activated:Once(EngineVersionGui.onJoinServerButtonTriggered)
			end
		end
	end)
end

function EngineVersionGui.onJoinServerButtonTriggered(): ()
	if (serverIsExperimentalBoolValue and serverIsExperimentalBoolValue.Value == true) then
		if isStudio then
			print("JoinServerButton triggered. Joining stable server...")
		end
		LoadingScreen.onTeleporting(3, function()
			TypedRemotes.JoinStableServer:FireServer()
		end)
	else
		if isStudio then
			print("JoinServerButton triggered. Joining testing server...")
		end
		LoadingScreen.onTeleporting(3, function()
			TypedRemotes.JoinTestingServer:FireServer()
		end)
	end
end

function EngineVersionGui.createNewEngineVersionGui(): ScreenGui
	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.Name = ENGINE_VERSION_SCREEN_GUI_NAME

	local rootFrame = Instance.new("Frame")
	rootFrame.BackgroundTransparency = 1
	rootFrame.Size = UDim2.fromScale(1, 1)
	rootFrame.Parent = newScreenGui

	local rootUiPadding = Instance.new("UIPadding")
	rootUiPadding.PaddingBottom = UDim.new(0, 10)
	rootUiPadding.PaddingLeft = UDim.new(0, 10)
	rootUiPadding.PaddingRight = UDim.new(0, 10)
	rootUiPadding.PaddingTop = UDim.new(0, 10)
	rootUiPadding.Parent = rootFrame

	local safeAreaFrame = Instance.new("Frame")
	safeAreaFrame.Name = "SafeArea"
	safeAreaFrame.BackgroundTransparency = 1
	safeAreaFrame.Size = UDim2.fromScale(1, 1)
	safeAreaFrame.Parent = rootFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 15)
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	listLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.VerticalFlex = Enum.UIFlexAlignment.None
	listLayout.Parent = safeAreaFrame

	local versionTextFrame = Instance.new("Frame")
	versionTextFrame.Name = "VersionTextFrame"
	versionTextFrame.BackgroundTransparency = 1
	versionTextFrame.Size = UDim2.fromOffset(649, 31)
	versionTextFrame.Parent = safeAreaFrame

	local versionTextListLayout = Instance.new("UIListLayout")
	versionTextListLayout.Padding = UDim.new(0, 0)
	versionTextListLayout.FillDirection = Enum.FillDirection.Vertical
	versionTextListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	versionTextListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	versionTextListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	versionTextListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	versionTextListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	versionTextListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	versionTextListLayout.Parent = versionTextFrame

	local headText = Instance.new("TextLabel")
	headText.Name = "EngineText"
	headText.BackgroundTransparency = 1
	headText.Size = UDim2.fromOffset(457, 17)
	headText.TextColor3 = Color3.new(1, 1, 1)
	headText.TextSize = 17
	headText.FontFace = Font.fromName("Zekton")
	headText.LayoutOrder = 0
	headText.TextXAlignment = Enum.TextXAlignment.Right
	headText.TextYAlignment = Enum.TextYAlignment.Top
	headText.Parent = versionTextFrame

	local versionText = Instance.new("TextLabel")
	versionText.Name = "VersionText"
	versionText.BackgroundTransparency = 1
	versionText.Size = UDim2.fromOffset(457, 13)
	versionText.TextColor3 = Color3.new(1, 1, 1)
	versionText.TextSize = 15
	versionText.FontFace = Font.fromName("Zekton")
	versionText.LayoutOrder = 1
	versionText.TextXAlignment = Enum.TextXAlignment.Right
	versionText.TextYAlignment = Enum.TextYAlignment.Top
	versionText.Parent = versionTextFrame
 
	EngineVersionGui.setEngineAndVersionTexts(headText, versionText)

	joinServerButton = EngineVersionGui.createNewJoinServerButton(safeAreaFrame)
	EngineVersionGui.setupJoinServerButtonIfValid(versionTextFrame)

	newScreenGui.Parent = playerGui

	return newScreenGui
end

function EngineVersionGui.createOrGetAndSetEngineVersionGui(): ScreenGui
	local engineVersionScreenGui = playerGui:FindFirstChild(ENGINE_VERSION_SCREEN_GUI_NAME) :: ScreenGui?

	if not engineVersionScreenGui then
		local newEngineVersionScreenGui = EngineVersionGui.createNewEngineVersionGui()
		engineVersionScreenGui = newEngineVersionScreenGui
		return newEngineVersionScreenGui
	end

	print(`'{ENGINE_VERSION_SCREEN_GUI_NAME}' ScreenGui already created.`)

	local rootFrame = engineVersionScreenGui:FindFirstChild("Frame") :: Frame
	local safeAreaFrame = rootFrame:FindFirstChild("SafeArea") :: Frame
	local versionTextFrame = safeAreaFrame:FindFirstChild("VersionTextFrame") :: Frame
	local engineText = versionTextFrame:FindFirstChild("EngineText") :: TextLabel
	local versionText = versionTextFrame:FindFirstChild("VersionText") :: TextLabel
	local foundJoinServerButton = safeAreaFrame:FindFirstChild("JoinServerButton") :: TextButton?
	if not foundJoinServerButton then
		foundJoinServerButton = EngineVersionGui.createNewJoinServerButton(safeAreaFrame)
	end

	joinServerButton = foundJoinServerButton
	EngineVersionGui.setEngineAndVersionTexts(engineText, versionText)
	EngineVersionGui.setupJoinServerButtonIfValid(versionTextFrame)

	return engineVersionScreenGui
end

return EngineVersionGui