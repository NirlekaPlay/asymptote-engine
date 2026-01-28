--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SHOW_POS = UDim2.fromScale(0, 0)
local HIDE_POS = UDim2.fromScale(0, -0.05)

local TWEEN_INFO_EXPO_IN = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_INFO_EXPO_IN_FAST = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local DIALOGUE_UI = ReplicatedStorage.shared.assets.gui.Dialogue

local ui = DIALOGUE_UI:Clone()
local gradientFrame = ui.Root.Gradient
local gradient = ui.Root.Gradient.UIGradient
local gradientTransparencyNumValue = Instance.new("NumberValue")
local dialogueFrame = ui.Root.DialogueFrame
local dialogueText = ui.Root.DialogueFrame.DialogueText
local dialogueSpeaker = ui.Root.DialogueFrame.SpeakerText

dialogueText.TextSize *= 1.2
dialogueSpeaker.TextSize *= 1.5

local startValue1 = 1
local goalValue1 = 0.0375

local startValue2 = 1 
local goalValue2 = 0.494

local startValue3 = 1
local goalValue3 = 1

gradientTransparencyNumValue.Changed:Connect(function(alpha)
	-- Linear interpolation: (start + (goal - start) * (1 - alpha))
	-- Note: Using (1 - alpha) because the goal is reached at alpha = 0
	
	local current1 = startValue1 + (goalValue1 - startValue1) * (1 - alpha)
	local current2 = startValue2 + (goalValue2 - startValue2) * (1 - alpha)
	local current3 = startValue3 + (goalValue3 - startValue3) * (1 - alpha)

	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, current1),
		NumberSequenceKeypoint.new(0.501, current2),
		NumberSequenceKeypoint.new(1, current3)
	})
end)

gradientTransparencyNumValue.Value = 1

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
	Returns the dialogue TextLabel instance.
]=]
function DialogueUIHandler.getDialogueTextLabel(): TextLabel
	return dialogueText
end

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
	local teenInfoText = show and TWEEN_INFO_EXPO_IN or TWEEN_INFO_EXPO_IN_FAST

	local targetTextTrans = show and 0 or 1

	TweenService:Create(dialogueSpeaker, teenInfoText, { TextTransparency = targetTextTrans }):Play()

	TweenService:Create(dialogueFrame, tweenInfo, { Position = targetPosition }):Play()
	
	if show then
		if textTransTween then
			textTransTween:Cancel()
		end
		dialogueText.TextTransparency = 0
	else
		textTransTween = TweenService:Create(dialogueText, teenInfoText, { TextTransparency = 1 })
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