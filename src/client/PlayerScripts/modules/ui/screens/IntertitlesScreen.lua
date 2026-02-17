--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UIAutoScaledText = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UIAutoScaledText)

local gui = ReplicatedStorage.shared.assets.gui.Intertitles:Clone()
local root = gui.Root
local backgroundFrame = root.SafeArea
local titleText = UIAutoScaledText.fromTextLabel(backgroundFrame.TextLabel, 1920, 40)

local TWEEN_INFO_EXPO_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

type DialogueStep = {
	text: string,
	duration: number
}

local SEQUENCE: {DialogueStep} = {
	{ text = "You are a newly promoted Tier 4 officer of Plasma Security Division.", duration = 5 },
	{ text = "The Council has tasked you to assassinate the equipment vendor named <b>Dennis.</b>", duration = 7 },
	{ text = "He is located in the newly built administration building in <b>Broken Hill</b>.", duration = 5 },
	{ text = 'A handler by the name of <b><font color="#0071FF">Alice</font></b> will guide you through the mission.', duration = 5 },
}

gui.Parent = Players.LocalPlayer.PlayerGui
titleText.Text = "<b>DONT RESIZE YOURSELF YOU FUCK</b>" -- Prevents the motherfucking gui from resizing whern theres a fucking bold text.

local function runSequence()
	backgroundFrame.BackgroundTransparency = 1
	titleText.TextTransparency = 1

	task.wait(1)

	TweenService:Create(backgroundFrame, TWEEN_INFO_EXPO_OUT, { BackgroundTransparency = 0 }):Play()
	task.wait(0.5)

	for i, step in SEQUENCE do
		if titleText.TextTransparency < 1 then
			local fadeOut = TweenService:Create(titleText, TWEEN_INFO_EXPO_OUT, { TextTransparency = 1 })
			fadeOut:Play()
			fadeOut.Completed:Wait()
		end

		titleText.Text = step.text

		TweenService:Create(titleText, TWEEN_INFO_EXPO_OUT, { TextTransparency = 0 }):Play()

		task.wait(step.duration)
	end
end

runSequence()

--[=[
	@class IntertitlesScreen
]=]
local IntertitlesScreen = {}

return IntertitlesScreen