--!strict

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
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
createNewPair("N", "Debug brain")
createNewPair("B", "Debug tracers")