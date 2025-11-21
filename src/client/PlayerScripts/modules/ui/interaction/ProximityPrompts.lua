--!nocheck

--[=[
	This a highly modified version of the default ProximityPrompt
	from the DevForum:
	https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
]=]

local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local LocalStatesHolder = require(StarterPlayer.StarterPlayerScripts.client.modules.states.LocalStatesHolder)
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ProximityPrompts = {}

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxView.png",
	[Enum.KeyCode.ButtonStart] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLB.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRB.png",
	[Enum.KeyCode.ButtonL2] = "rbxasset://textures/ui/Controls/xboxLT.png",
	[Enum.KeyCode.ButtonR2] = "rbxasset://textures/ui/Controls/xboxRT.png",
	[Enum.KeyCode.ButtonL3] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR3] = "rbxasset://textures/ui/Controls/xboxRS.png",
	[Enum.KeyCode.Thumbstick1] = "rbxasset://textures/ui/Controls/xboxLSDirectional.png",
	[Enum.KeyCode.Thumbstick2] = "rbxasset://textures/ui/Controls/xboxRSDirectional.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

local function getScreenGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

local function createProgressBarGradient(parent: Instance, leftSide: boolean)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.Position = UDim2.fromScale(leftSide and 0 or 0.5, 0)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Parent = parent

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(leftSide and 0 or -1, 0)
	image.Image = "rbxasset://textures/ui/Controls/RadialFill.png"
	image.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4999, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = leftSide and 180 or 0
	gradient.Parent = image

	return gradient
end

local function createCircularProgressBar()
	local bar = Instance.new("Frame")
	bar.Name = "CircularProgressBar"
	bar.Size = UDim2.fromOffset(58, 58)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.BackgroundTransparency = 1

	local gradient1 = createProgressBarGradient(bar, true)
	local gradient2 = createProgressBarGradient(bar, false)

	local progress = Instance.new("NumberValue")
	progress.Name = "Progress"
	progress.Parent = bar
	progress.Changed:Connect(function(value) -- TODO: Possible memory leak?
		local angle = math.clamp(value * 360, 0, 360)
		gradient1.Rotation = math.clamp(angle, 180, 360)
		gradient2.Rotation = math.clamp(angle, 0, 180)
	end)

	return bar
end

local promptParts: { [BasePart]: true } = {}

local function createPrompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, gui: ScreenGui): () -> ()
	local tweensForButtonHoldBegin: { Tween } = {}
	local tweensForButtonHoldEnd: { Tween } = {}
	local tweensForFadeOut: { Tween } = {}
	local tweensForFadeIn: { Tween } = {}
	local tweenInfoInFullDuration =
		TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	--local tweenInfoOutHalfSecond = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoQuick = TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenInfoExpoQuick = TweenInfo.new(0.06, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

	local tweensForButtonHoldBeginTransparency = 0.5

	local promptParentAttatchment = prompt.Parent :: Attachment

	-- To know if the ProximityPrompt can be the normal one or the flat one.
	local isOmniDir = promptParentAttatchment:GetAttribute("OmniDir")

	local promptPart
	promptPart = Instance.new("Part")
	promptPart.Name = "PromptPart"
	promptPart.Anchored = true
	promptPart.CanCollide = false
	promptPart.CanTouch = false
	promptPart.CanQuery = false
	promptPart.CastShadow = false
	promptPart.Transparency = 1
	promptPart.CFrame = promptParentAttatchment.WorldCFrame
	promptPart.Parent = workspace

	if isOmniDir then
		promptParts[promptPart] = true
	end

	local promptUI = Instance.new("SurfaceGui")
	promptUI.Name = "Prompt"
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.07)
	frame.Parent = promptUI

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.Parent = frame

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.fromScale(1, 1)
	inputFrame.BackgroundTransparency = 1
	inputFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	inputFrame.Parent = frame

	local resizeableInputFrame = Instance.new("Frame")
	resizeableInputFrame.Size = UDim2.fromScale(1, 1)
	resizeableInputFrame.Position = UDim2.fromScale(0.5, 0.5)
	resizeableInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resizeableInputFrame.BackgroundTransparency = 1
	resizeableInputFrame.Parent = inputFrame

	local inputFrameScaler = Instance.new("UIScale")
	inputFrameScaler.Parent = resizeableInputFrame

	local inputFrameScaleFactor = inputType == Enum.ProximityPromptInputType.Touch and 1.6 or 0.8
	table.insert(
		tweensForButtonHoldBegin,
		TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = inputFrameScaleFactor })
	)
	table.insert(tweensForButtonHoldEnd, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = 1 }))

	local actionTextFontSize = 32
	local objectTextFontSize = 15

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.FontFace = Font.fromName("Zekton")
	actionText.TextSize = actionTextFontSize
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = Color3.new(1, 1, 1)
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.Parent = frame
	table.insert(tweensForButtonHoldBegin, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = tweensForButtonHoldBeginTransparency }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.fromScale(1, 1)
	objectText.FontFace = Font.fromName("Zekton")
	objectText.TextSize = objectTextFontSize
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	objectText.TextXAlignment = Enum.TextXAlignment.Left
	objectText.Parent = frame

	table.insert(tweensForButtonHoldBegin, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = tweensForButtonHoldBeginTransparency }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))

	table.insert(
		tweensForButtonHoldBegin,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = tweensForButtonHoldBeginTransparency })
	)
	table.insert(
		tweensForButtonHoldEnd,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	)
	table.insert(
		tweensForFadeOut,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 1 })
	)
	table.insert(
		tweensForFadeIn,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	)

	if prompt.HoldDuration > 0 then
		local roundFrame = Instance.new("Frame")
		roundFrame.Name = "RoundFrame"
		roundFrame.Size = UDim2.fromOffset(45, 45)

		roundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		roundFrame.Position = UDim2.fromScale(0.5, 0.5)
		roundFrame.BackgroundTransparency = 1
		roundFrame.Parent = resizeableInputFrame

		local roundedFrameCorner = Instance.new("UICorner")
		roundedFrameCorner.CornerRadius = UDim.new(0.15, 0)
		roundedFrameCorner.Parent = roundFrame

		table.insert(tweensForFadeOut, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 0.5 }))
	end

	--

	local roundFrameFront = Instance.new("Frame")
	roundFrameFront.Name = "RoundFrameFront"
	roundFrameFront.Size = prompt.HoldDuration > 0 and UDim2.fromOffset(40, 40) or UDim2.fromOffset(45, 45)

	roundFrameFront.AnchorPoint = Vector2.new(0.5, 0.5)
	roundFrameFront.Position = UDim2.fromScale(0.5, 0.5)
	roundFrameFront.BackgroundTransparency = 0
	roundFrameFront.BackgroundColor3 = Color3.new(1, 1, 1)
	roundFrameFront.Parent = resizeableInputFrame

	local roundFrameFrontCorner = Instance.new("UICorner")
	roundFrameFrontCorner.CornerRadius = UDim.new(0.15, 0)
	roundFrameFrontCorner.Parent = roundFrameFront

	table.insert(tweensForFadeOut, TweenService:Create(roundFrameFront, tweenInfoQuick, { BackgroundTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(roundFrameFront, tweenInfoQuick, { BackgroundTransparency = 0 }))

	if inputType == Enum.ProximityPromptInputType.Gamepad then
		if GamepadButtonImage[prompt.GamepadKeyCode] then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(24, 24)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = GamepadButtonImage[prompt.GamepadKeyCode]
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		end
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(25, 31)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
		buttonImage.Parent = resizeableInputFrame

		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))
	else
		--[[local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(28, 30)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/key_single.png"
		buttonImage.Parent = resizeableInputFrame
		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))]]

		local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

		local buttonTextImage: string? = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(36, 36)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = buttonTextImage
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		elseif buttonTextString ~= nil and buttonTextString ~= "" then
			local buttonText = Instance.new("TextLabel")
			buttonText.Name = "ButtonText"
			buttonText.Position = UDim2.fromOffset(0, -1)
			buttonText.Size = UDim2.fromScale(1, 1)
			buttonText.FontFace = Font.fromName("Zekton")
			buttonText.TextSize = 30
			if string.len(buttonTextString :: string) > 2 then
				buttonText.TextSize = 12
			end
			buttonText.BackgroundTransparency = 1
			buttonText.TextTransparency = 1
			buttonText.TextColor3 = Color3.new(0, 0, 0)
			buttonText.TextXAlignment = Enum.TextXAlignment.Center
			buttonText.Text = buttonTextString
			buttonText.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 0 }))
		else
			error(
				"ProximityPrompt '"
					.. prompt.Name
					.. "' has an unsupported keycode for rendering UI: "
					.. tostring(prompt.KeyboardKeyCode)
			)
		end
	end

	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.TextTransparency = 1
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = promptUI

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.MouseButton1
				) and input.UserInputState ~= Enum.UserInputState.Change
			then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)

		promptUI.Active = true
	end

	if prompt.HoldDuration > 0 then
		local circleBar = createCircularProgressBar()
		circleBar.Parent = resizeableInputFrame
		table.insert(
			tweensForButtonHoldBegin,
			TweenService:Create(circleBar.Progress, tweenInfoInFullDuration, { Value = 1 })
		)
		table.insert(
			tweensForButtonHoldEnd,
			TweenService:Create(circleBar.Progress, tweenInfoExpoQuick, { Value = 0 })
		)
	end

	local holdBeganConnection
	local holdEndedConnection
	local triggeredConnection
	local triggerEndedConnection

	if prompt.HoldDuration > 0 then
		holdBeganConnection = prompt.PromptButtonHoldBegan:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldBegin) do
				tween:Play()
			end
		end)

		holdEndedConnection = prompt.PromptButtonHoldEnded:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldEnd) do
				tween:Play()
			end
		end)
	end

	triggeredConnection = prompt.Triggered:Connect(function()
		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end
	end)

	triggerEndedConnection = prompt.TriggerEnded:Connect(function()
		for _, tween in ipairs(tweensForFadeIn) do
			tween:Play()
		end
	end)

	local function updateUIFromPrompt()
		-- todo: Use AutomaticSize instead of GetTextSize when that feature becomes available
		local actionTextSize =
			TextService:GetTextSize(prompt.ActionText, actionTextFontSize, Enum.Font.GothamMedium, Vector2.new(1000, 1000))
		local objectTextSize =
			TextService:GetTextSize(prompt.ObjectText, objectTextFontSize, Enum.Font.GothamMedium, Vector2.new(1000, 1000))
		local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
		local promptHeight = 60
		local promptWidth = 60
		local textPaddingLeft = 62
		local textPaddingRight = 5

		if
			(prompt.ActionText ~= nil and prompt.ActionText ~= "")
			or (prompt.ObjectText ~= nil and prompt.ObjectText ~= "")
		then
			promptWidth = maxTextWidth + textPaddingLeft + textPaddingRight
		end

		local isObjectTextPresent = (prompt.ObjectText ~= nil and prompt.ObjectText ~= "")

		-- If object text is present, calculate the Y offset (9) for objectText
		local actionTextYOffset = 0
		if isObjectTextPresent then
			actionTextYOffset = 12
		end
		
		objectText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYOffset)
		
		local actionTextYPosition = -10 -- Default position for actionText when both are displayed
		
		if not isObjectTextPresent then
			-- Calculate the offset needed to vertically center the text label
			-- Container center (15) - half of the actionText label's calculated height
			actionTextYPosition = 15 - (actionTextSize.Y / 2)
		end
		
		-- The resulting Y position must be a UDim2 offset, not scale (0)
		actionText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYPosition)

		actionText.Text = prompt.ActionText
		objectText.Text = prompt.ObjectText
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable

		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		--[[if isOmniDir and promptUI:IsA("BillboardGui") then
			promptUI.Size = UDim2.fromOffset(promptWidth, promptHeight)
			promptUI.SizeOffset =
				Vector2.new(prompt.UIOffset.X / promptUI.Size.Width.Offset, prompt.UIOffset.Y / promptUI.Size.Height.Offset)
		else]]
		local pixelsPerStud = 55

		-- Convert pixels to studs
		promptUI.CanvasSize = Vector2.new(promptWidth, promptHeight)
		local partWidth = promptWidth / pixelsPerStud
		local partHeight = promptHeight / pixelsPerStud
		promptPart.Size = Vector3.new(partWidth, partHeight, 0.2)
		--end
	end

	local changedConnection = prompt.Changed:Connect(updateUIFromPrompt)
	updateUIFromPrompt()

	--[[if isOmniDir then 
		promptUI.Adornee = prompt.Parent
		promptUI.Parent = gui
	else]]
		promptUI.Adornee = promptPart
		promptUI.Parent = gui
	--end

	for _, tween in ipairs(tweensForFadeIn) do
		tween:Play()
	end

	local function cleanup()
		if holdBeganConnection then
			holdBeganConnection:Disconnect()
		end

		if holdEndedConnection then
			holdEndedConnection:Disconnect()
		end

		triggeredConnection:Disconnect()
		triggerEndedConnection:Disconnect()
		changedConnection:Disconnect()

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		task.wait(0.2)

		promptUI.Parent = nil
		promptPart.Parent = nil
	end

	return cleanup
end

local function createNonInteractivePrompt(prompt: ProximityPrompt, message: string, gui: ScreenGui): ()
	local tweensForFadeOut: { Tween } = {}
	local tweensForFadeIn: { Tween } = {}
	local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local promptParentAttatchment = prompt.Parent :: Attachment

	-- To know if the ProximityPrompt can be the normal one or the flat one.
	local isOmniDir = promptParentAttatchment:GetAttribute("OmniDir")

	local promptPart
	promptPart = Instance.new("Part")
	promptPart.Name = "PromptPart"
	promptPart.Anchored = true
	promptPart.CanCollide = false
	promptPart.CanTouch = false
	promptPart.CanQuery = false
	promptPart.CastShadow = false
	promptPart.Transparency = 1
	promptPart.CFrame = promptParentAttatchment.WorldCFrame
	promptPart.Parent = workspace

	if isOmniDir then
		promptParts[promptPart] = true
	end

	local promptUI = Instance.new("SurfaceGui")
	promptUI.Name = "Prompt"
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.07)
	frame.Parent = promptUI

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.Parent = frame

	local actionTextFontSize = 15
	local objectTextFontSize = 15

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Position = UDim2.fromScale(0.5, 0.5)
	actionText.AnchorPoint = Vector2.new(0.5, 0.5)
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.FontFace = Font.fromName("Zekton")
	actionText.TextSize = actionTextFontSize
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	actionText.TextXAlignment = Enum.TextXAlignment.Center
	actionText.Parent = frame
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	--[[local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.fromScale(1, 1)
	objectText.FontFace = Font.fromName("Zekton")
	objectText.TextSize = objectTextFontSize
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	objectText.TextXAlignment = Enum.TextXAlignment.Left
	objectText.Parent = frame
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))]]

	table.insert(
		tweensForFadeOut,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 1 })
	)
	table.insert(
		tweensForFadeIn,
		TweenService:Create(frame, tweenInfoFast, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	)

	--

	local function updateUIFromPrompt()
		-- TODO: Use AutomaticSize instead of GetTextSize when that feature becomes available
		local actionTextSize =
			TextService:GetTextSize(message, actionTextFontSize, Enum.Font.GothamMedium, Vector2.new(1000, 1000))
		local objectTextSize =
			TextService:GetTextSize(prompt.ObjectText, objectTextFontSize, Enum.Font.GothamMedium, Vector2.new(1000, 1000))
		local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
		local promptHeight = 60
		local promptWidth = 60
		local textPaddingLeft = 10
		local textPaddingRight = 10

		if
			(message ~= nil and prompt.ActionText ~= "")
			or (prompt.ObjectText ~= nil and prompt.ObjectText ~= "")
		then
			promptWidth = maxTextWidth + textPaddingLeft + textPaddingRight
		end

		local isObjectTextPresent = (prompt.ObjectText ~= nil and prompt.ObjectText ~= "")

		-- If object text is present, calculate the Y offset (9) for objectText
		local actionTextYOffset = 0
		if isObjectTextPresent then
			actionTextYOffset = 12
		end
		
		--objectText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYOffset)
		
		
		-- The resulting Y position must be a UDim2 offset, not scale (0)
		--actionText.Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYPosition)

		actionText.Text = message
		--objectText.Text = prompt.ObjectText
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable

		--objectText.AutoLocalize = prompt.AutoLocalize
		--objectText.RootLocalizationTable = prompt.RootLocalizationTable

		local pixelsPerStud = 55

		-- Convert pixels to studs
		promptUI.CanvasSize = Vector2.new(promptWidth, promptHeight)
		local partWidth = promptWidth / pixelsPerStud
		local partHeight = promptHeight / pixelsPerStud
		promptPart.Size = Vector3.new(partWidth, partHeight, 0.2)
	end

	local changedConnection = prompt.Changed:Connect(updateUIFromPrompt)
	updateUIFromPrompt()

	promptUI.Adornee = promptPart
	promptUI.Parent = gui

	for _, tween in tweensForFadeIn do
		tween:Play()
	end

	local function cleanup()
		if changedConnection then
			changedConnection:Disconnect()
		end

		for _, tween in tweensForFadeOut do
			tween:Play()
		end

		task.wait(0.2)

		promptUI.Parent = nil
		promptPart.Parent = nil
	end

	return cleanup
end

local function flat(t1: {[any]:any}, t2: {[any]:any}): {[any]:any}
	local newTable: {[any]:any} = {}

	for key, value in pairs(t1) do
		newTable[key] = value
	end

	for key, value in pairs(t2) do
		newTable[key] = value
	end

	return newTable
end

local function parseCondition(str: string): any
	return ExpressionParser.parseAndEvalute(str, ExpressionContext.new(
		flat(
			LocalStatesHolder.getAllStates(),
			ReplicatedGlobalStates.getAllStates()
		)
	))
end

--

local CFRAME_FLIP_ROT = CFrame.Angles(0, math.rad(180), 0)

local function isPromptPartValid(part: BasePart): boolean
	if not part then
		return false
	end

	if part.Parent == nil or not part:IsDescendantOf(workspace) then
		return false
	end

	return true
end

local function removeInvalidPromptParts(): ()
	local partsToRemove: { [BasePart]: true } = {}

	-- I don't know anymore.
	for promptPart in promptParts do
		if not isPromptPartValid(promptPart) then
			partsToRemove[promptPart] = true
		end
	end

	for promptPart in partsToRemove do
		promptParts[promptPart] = nil
	end
end

local function updatePartPromptsCframe(): ()
	if next(promptParts) == nil then
		return
	end

	local cameraCFrame = Camera.CFrame

	for promptPart in promptParts do
		promptPart.CFrame = (cameraCFrame.Rotation * CFRAME_FLIP_ROT) + promptPart.Position
	end
end

function ProximityPrompts.update(): ()
	removeInvalidPromptParts()
	updatePartPromptsCframe()
end

function ProximityPrompts.onPromptShown(intPrompt, inputType: Enum.ProximityPromptInputType): ()
	local prompt = intPrompt:getProximityPrompt()
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		return
	end

	local promptAtt = prompt.Parent :: Attachment?
	if not promptAtt or not promptAtt:IsA("Attachment") then
		warn(`{prompt:GetFullName()}: Is not parented to an Attachment.`)
		return
	end

	local clientCondition = promptAtt:GetAttribute("PrimaryHoldClientShowCondition") :: string?
	local failTitle: string?
	if clientCondition then
		local success = parseCondition(clientCondition)
		print(`{prompt:GetFullName()}: Has show condition. Evaluated. Result:`, success)
		if not success then
			local failMsg = promptAtt:GetAttribute("PrimaryHoldConditionFailTitle") :: string?
			print("FOUND FAIL MESSAGE:", failMsg)
			if not failMsg then
				return
			end

			failTitle = ClientLanguage.getOrDefault(failMsg, failMsg)

			print("NOT SHOWN")
			print("FAIL TITLE:", failTitle)
		end
	end

	local gui = getScreenGui()

	-- TODO: Abritary Proximity Prompt bypass bullshit by locally disabling them
	-- but that ALSO disables the distance and LoS checks, so we gotta do that shit
	-- manually tooo????? oh fuck.

	-- If you still dont get the problem, the Proximity Prompt is still enabled.
	-- Even though its supposed to be not interactive.

	-- ~~But I think I'm onto something here.. what IF. Instead of going insane and
	-- painstakingly implement a check every frame on every proximity prompt if they should
	-- be shown, why not just locally disable the proximity prompt if invalid, ~~

	-- I lost track.
	local cleanupFunction = failTitle and createNonInteractivePrompt(prompt, failTitle, gui) or
		createPrompt(prompt, inputType, gui)

	local hiddenConn: RBXScriptConnection
	local changedConn: RBXScriptConnection
	local statesChangedConn: RBXScriptConnection
	local replicatedGlobalStatesChangedConn: RBXScriptConnection

	local function onShitChanged()
		print("Proximity prompt: Something changed. Evaluating stuff...")
		-- TODO: Someone fix this convoluted bullshit with something sane
		-- and pleasing to the eyes, thank you.

		-- God I hate this shit. So many variables, so many connections, so many ways
		-- states, stuff, edge cases, everything, can change. And we need to fucking
		-- cover allat.
		local shouldInvalidate = false
		local shouldNotShowPromptAnyway = prompt.Enabled --prompt.MaxActivationDistance <= 0 or not
		local makeNonInteractive = false
		if shouldNotShowPromptAnyway then
			shouldInvalidate = true
		else
			-- If the states are now invalid, it should hide the interactive prompt
			-- and switch to the non interactive one.
			if clientCondition then
				local success = parseCondition(clientCondition)
				print("Client condition found. Condition result:", success)
				if not success then
					shouldInvalidate = true
					local failMsg = promptAtt:GetAttribute("PrimaryHoldConditionFailTitle") :: string?
					print("INVALIDATED: FOUND ERROR MESSAGE:", failMsg)
					if failMsg then
						makeNonInteractive = true
						failTitle = ClientLanguage.getOrDefault(failMsg, failMsg)
					end
				end
			end
		end
		if shouldInvalidate then
			cleanupFunction()
			if (makeNonInteractive == false) and hiddenConn then
				print("Hidden connection disconnected")
				hiddenConn:Disconnect()
				hiddenConn = nil
			end

			if changedConn then
				changedConn:Disconnect()
				changedConn = nil
			end

			if statesChangedConn then
				statesChangedConn:Disconnect()
				statesChangedConn = nil
			end

			if replicatedGlobalStatesChangedConn then
				replicatedGlobalStatesChangedConn:Disconnect()
				replicatedGlobalStatesChangedConn = nil
			end

			if makeNonInteractive and failTitle then
				-- 1. Create the non-interactive UI
				cleanupFunction = createNonInteractivePrompt(prompt, failTitle, gui)

				-- 2. Establish the ONE-TIME cleanup mechanism for this new UI
				if hiddenConn then
					hiddenConn:Disconnect()
				end
				
				hiddenConn = intPrompt.WrappedPromptHidden:Once(function()
					cleanupFunction() -- Destroys the non-interactive UI
					
					-- Since the prompt is now hidden, all change listeners related 
					-- to this *showing* state should also be disconnected to avoid running
					-- the evaluation logic while the prompt is invisible/off-screen.
					if changedConn then changedConn:Disconnect(); changedConn = nil end
					if statesChangedConn then statesChangedConn:Disconnect(); statesChangedConn = nil end
					if replicatedGlobalStatesChangedConn then replicatedGlobalStatesChangedConn:Disconnect(); replicatedGlobalStatesChangedConn = nil end
				end)
			end
		end
	end

	changedConn = prompt.Changed:Connect(onShitChanged)

	statesChangedConn = LocalStatesHolder.getStatesChangedConnection():Connect(onShitChanged)
	replicatedGlobalStatesChangedConn = ReplicatedGlobalStates.getStatesChangedConnection():Connect(onShitChanged)

	hiddenConn = intPrompt.WrappedPromptHidden:Once(function()
		--print("Prompt hidden")
		cleanupFunction()
	end)
end

return ProximityPrompts