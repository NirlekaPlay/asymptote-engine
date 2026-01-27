--!strict

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local ui = playerGui:WaitForChild("Interaction")
local ui_keySideFrame = ui.Root.KeySide
local ui_actionSideFrame = ui.Root.NameSide

local REF_KEY = ui_keySideFrame.REF
local REF_ACTION = ui_actionSideFrame.REF
local PREFIX = "- "
local BLACK = Color3.new(0, 0, 0)

local ROOT_OFF_SCREEN_POS = UDim2.new(0.5, 0, -1, 0)
local ROOT_ON_SCREEN_POS = UDim2.new(0.5, 0, 0, 0)
local SHOW_TWEEN_DUR = 0.5
local TWEEN_INFO_IN = TweenInfo.new(
	SHOW_TWEEN_DUR,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

ui.Root.AnchorPoint = Vector2.new(0.5, 0)
ui.Root.Position = ROOT_OFF_SCREEN_POS

ui.Enabled = true

local function createNewPair(keyStr: string, actionStr: string): ()
	local keyTextFrame = REF_KEY:Clone()
	local keyTextLabel = keyTextFrame.REF
	keyTextLabel.Text = keyStr
	keyTextLabel.Visible = true
	keyTextFrame.Parent = ui_keySideFrame

	local keyTextLabel_shadow = UITextShadow.createTextShadow(keyTextLabel, nil, 3, nil, 0.5)
	keyTextLabel_shadow.BackgroundColor3 = BLACK
	keyTextLabel_shadow.BackgroundTransparency = 0.5

	local actionTextFrame = REF_ACTION:Clone()
	local actionTextLabel = actionTextFrame.REF
	actionTextLabel.Text = PREFIX .. actionStr
	actionTextLabel.Visible = true
	actionTextFrame.Parent = ui_actionSideFrame

	local _actionTextLabel_shadow = UITextShadow.createTextShadow(actionTextLabel, nil, 3, nil, 0.5)
end

local function onLoad(): ()
	REF_KEY.REF.Visible = false
	REF_ACTION.REF.Visible = false
end

onLoad()

createNewPair("H", "Help")
createNewPair("L", "Toggle Mouse Unlock")
createNewPair("N", "Debug brain")
createNewPair("B", "Debug tracers")

task.wait(5)

TweenService:Create(ui.Root, TWEEN_INFO_IN, { Position = ROOT_ON_SCREEN_POS }):Play()