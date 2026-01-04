--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SHOW_POS = UDim2.fromScale(0, 0)
local HIDE_POS = UDim2.fromScale(0, 0.05)

local TWEEN_INFO_EXPO_IN = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local DIALOGUE_UI = ReplicatedStorage.shared.assets.gui.Dialogue

local ui = DIALOGUE_UI:Clone()
local gradientFrame = ui.Root.Gradient
local gradient = ui.Root.Gradient.UIGradient
local gradientTransparencyNumValue = Instance.new("NumberValue")
local dialogueFrame = ui.Root.DialogueFrame
local dialogueText = ui.Root.DialogueFrame.DialogueText
local dialogueSpeaker = ui.Root.DialogueFrame.SpeakerText

gradientTransparencyNumValue.Value = 1

gradientTransparencyNumValue.Changed:Connect(function(value)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, value),
		NumberSequenceKeypoint.new(1, 1)
	})
end)

ui.Parent = Players.LocalPlayer.PlayerGui
dialogueFrame.ZIndex = 2
gradientFrame.ZIndex = 1
dialogueFrame.Position = HIDE_POS

dialogueSpeaker.BackgroundTransparency = 1
dialogueSpeaker.TextTransparency = 1
dialogueSpeaker.RichText = true
dialogueText.TextTransparency = 1
dialogueText.RichText = true

local textTransTween: Tween? = nil

--[=[
	@class DialogueUIHandler

	A set of methods to handle the dialogue UI.
]=]
local DialogueUIHandler = {}

--[=[
	Sets the speaker text which appears above the dialogue text.
	`str` can also include Rich text.
]=]
function DialogueUIHandler.setSpeakertext(str: string): ()
	dialogueSpeaker.Text = str
end

--[=[
	Sets the dialogue text for when a character is talking.
	`str` can also include Rich text.
]=]
function DialogueUIHandler.setDialogueText(str: string): ()
	dialogueText.Text = str
end

--[=[
	Plays an animation showing or hiding the entire dialogue UI.
	Already gracefully handles interruptions. This method can be called
	many times without any issues.
]=]
function DialogueUIHandler.transitionDialogue(show: boolean)
	local targetPosition = show and SHOW_POS or HIDE_POS
	local tweenInfo = show and TWEEN_INFO_EXPO_IN or TWEEN_INFO_EXPO_IN
	
	local targetTrans = show and 0 or 1
	local targetTextTrans = show and 0 or 1
	
	TweenService:Create(dialogueSpeaker, tweenInfo, { BackgroundTransparency = targetTrans }):Play()
	TweenService:Create(dialogueSpeaker, tweenInfo, { TextTransparency = targetTextTrans }):Play()

	TweenService:Create(dialogueFrame, tweenInfo, { Position = targetPosition }):Play()
	
	if show then
		if textTransTween then
			textTransTween:Cancel()
		end
		dialogueText.TextTransparency = 0
	else
		textTransTween = TweenService:Create(dialogueText, tweenInfo, { TextTransparency = 1 })
		textTransTween:Play()
	end

	if show then
		TweenService:Create(
			gradientTransparencyNumValue, TWEEN_INFO_EXPO_IN, { Value = 0 }
		):Play()
	else
		TweenService:Create(
			gradientTransparencyNumValue, TWEEN_INFO_EXPO_IN, { Value = 1 }
		):Play()
	end
end

--[=[
	To test how robust it is to handle interruptions:

	```lua
	local ContextActionService = game:GetService("ContextActionService")

	ContextActionService:BindAction("TestDia", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
		if inputState == Enum.UserInputState.Begin then
			DialogueUIHandler.transitionDialogue(true)
		else
			DialogueUIHandler.transitionDialogue(false)
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.L)
	```
]=]

return DialogueUIHandler