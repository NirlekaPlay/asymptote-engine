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
	duration: number
}

local intertitlesThread: thread? = nil

backgroundFrame.BackgroundTransparency = 1
titleTextRef.TextTransparency = 1
gui.Parent = Players.LocalPlayer.PlayerGui
titleTextRef.Text = "<b>DONT RESIZE YOURSELF YOU DOORKNOB</b>" -- Prevents the motherfucking gui from resizing whern theres a fucking bold text.

--[=[
	@class IntertitlesScreen
]=]
local IntertitlesScreen = {}

function IntertitlesScreen.runSequence(sequence: {{DialogueStep}}): ()
	if intertitlesThread then
		task.cancel(intertitlesThread)
		intertitlesThread = nil
	end

	intertitlesThread = task.spawn(function()
		IntertitlesScreen.runSequenceThread(sequence)
	end)
end

function IntertitlesScreen.runSequenceThread(sequence: {{DialogueStep}}): ()
	backgroundFrame.BackgroundTransparency = 1
	titleTextRef.TextTransparency = 1

	task.wait(1)

	TweenService:Create(backgroundFrame, TWEEN_INFO_EXPO_OUT, { BackgroundTransparency = 0 }):Play()

	task.wait(0.5)

	for i, mStep in sequence do
		local currentScreenTexts: { TextLabel } = {}
		for j, step in mStep do
			local titleText = titleTextRef:Clone()
			titleText.Parent = backgroundFrame
			titleText.Text = step.text
			titleText.TextTransparency = 1
			currentScreenTexts[j] = UIAutoScaledText.fromTextLabel(titleText, 1920, 40)
		end

		for j, step in mStep do
			local titleText = currentScreenTexts[j]
			TweenService:Create(titleText, TWEEN_INFO_EXPO_OUT, { TextTransparency = 0 }):Play()
			task.wait(step.duration)
		end
		
		for _, text in currentScreenTexts do
			local fadeOut = TweenService:Create(text, TWEEN_INFO_EXPO_OUT, { TextTransparency = 1 })
			fadeOut:Play()
			fadeOut.Completed:Once(function()
				text:Destroy()
			end)
		end
		
		task.wait(0.5)
	end
	
	TweenService:Create(backgroundFrame, TWEEN_INFO_EXPO_OUT, { BackgroundTransparency = 1 }):Play()
end

return IntertitlesScreen