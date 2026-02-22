--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UIAutoScaledText = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UIAutoScaledText)

local gui = ReplicatedStorage.shared.assets.gui.Intertitles:Clone()
local root = gui.Root
local backgroundFrame = root.SafeArea
local titleTextRef = backgroundFrame.REF

local TWEEN_INFO_EXPO_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

type DialogueStep = {
	text: string,
	duration: number,
	onVisible: (() -> ())?
}

backgroundFrame.BackgroundTransparency = 1
titleTextRef.TextTransparency = 1
gui.Parent = Players.LocalPlayer.PlayerGui
titleTextRef.Text = "<b>DONT RESIZE YOURSELF YOU DOORKNOB</b>" -- Prevents the motherfucking gui from resizing whern theres a fucking bold text.

--[=[
	@class IntertitlesScreen
]=]
local IntertitlesScreen = {}

function IntertitlesScreen.prepare(): ()
	backgroundFrame.BackgroundTransparency = 1
	titleTextRef.TextTransparency = 1
end

function IntertitlesScreen.fadeIn(): ()
	task.wait(1)

	TweenService:Create(backgroundFrame, TWEEN_INFO_EXPO_OUT, { BackgroundTransparency = 0 }):Play()

	task.wait(0.5)
end

function IntertitlesScreen.fadeOut(): ()
	TweenService:Create(backgroundFrame, TWEEN_INFO_EXPO_OUT, { BackgroundTransparency = 1 }):Play()
end

function IntertitlesScreen.createLine(text: string): TextLabel
	local titleText = titleTextRef:Clone()
	titleText.Parent = backgroundFrame
	titleText.Text = text
	titleText.TextTransparency = 1

	return UIAutoScaledText.fromTextLabel(titleText, 1920, 40)
end

function IntertitlesScreen.runSequenceThread(sequence: {{DialogueStep}}): ()
	for _, mStep in sequence do
		local currentElements = {}

		for j, step in mStep do
			local rawLabel = IntertitlesScreen.createLine(step.text)
			currentElements[j] = {raw = rawLabel, stepData = step}
		end

		for _, item in currentElements do
			if item.stepData.onVisible then
				task.spawn(item.stepData.onVisible)
			end

			TweenService:Create(item.raw, TWEEN_INFO_EXPO_OUT, { TextTransparency = 0 }):Play()
			task.wait(item.stepData.duration)
		end

		for _, item in currentElements do
			local fadeOut = TweenService:Create(item.raw, TWEEN_INFO_EXPO_OUT, { TextTransparency = 1 })
			fadeOut:Play()
			fadeOut.Completed:Once(function()
				item.raw:Destroy()
			end)
		end
		
		task.wait(0.5)
	end
end

return IntertitlesScreen