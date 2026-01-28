--!nocheck

--[=[
	Renders custom proximity prompts.
	This a highly modified version of the default ProximityPrompt from the DevForum:
	https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
]=]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TriggerAttributes = require(ReplicatedStorage.shared.world.interaction.attributes.TriggerAttributes)
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local UIGradientWipe = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UIGradientWipe)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InteractionPromptRenderer = {}

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

local CFRAME_FLIP_ROT = CFrame.Angles(0, math.rad(180), 0)
local BASE_REF = 65
local OLD_PIXELS_PER_STUD = 200
local NEW_PIXELS_PER_STUD = 200
local SCALE_MULTIPLIER = NEW_PIXELS_PER_STUD / BASE_REF
local SCALE_MULTIPLIER_OLD = OLD_PIXELS_PER_STUD / BASE_REF

type RenderedPrompts = {
	part: BasePart,
	attachment: Attachment,
	omniDir: boolean,
	shouldUpdatePosition: boolean
}

local renderedPrompts: { [RenderedPrompts]: true } = {}

local MAIN_FONT = Font.fromName("Zekton")

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
	bar.Visible = false
	bar.Name = "CircularProgressBar"
	bar.Size = UDim2.fromOffset(58 * SCALE_MULTIPLIER_OLD, 58 * SCALE_MULTIPLIER_OLD)
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

		bar.Visible = not (value <= 0)
	end)

	return bar
end

local function isPromptPartValid(part: BasePart): boolean
	if not part then
		return false
	end

	if part.Parent == nil or not part:IsDescendantOf(workspace) then
		return false
	end

	return true
end

function InteractionPromptRenderer.removeInvalidPromptParts(): ()
	local promptsToRemove: { [RenderedPrompts]: true } = {}

	-- I don't know anymore.
	for renderedPrompt in renderedPrompts do
		if not isPromptPartValid(renderedPrompt.part) then
			promptsToRemove[renderedPrompt] = true
		end
	end

	for renderedPrompt in promptsToRemove do
		renderedPrompts[renderedPrompt] = nil
	end
end

function InteractionPromptRenderer.updatePartPromptsCframe(): ()
	if next(renderedPrompts) == nil then
		return
	end

	local cameraCFrame = Camera.CFrame

	for renderedPrompt in renderedPrompts do
		if renderedPrompt.shouldUpdatePosition then
			if renderedPrompt.attachment.WorldPosition ~= renderedPrompt.part.Position then
				renderedPrompt.part.Position = renderedPrompt.attachment.WorldPosition
			end
		end

		if renderedPrompt.omniDir then
			renderedPrompt.part.CFrame = (cameraCFrame.Rotation * CFRAME_FLIP_ROT) + renderedPrompt.part.Position
		end
	end
end

function InteractionPromptRenderer.update(): ()
	InteractionPromptRenderer.removeInvalidPromptParts()
	InteractionPromptRenderer.updatePartPromptsCframe()
end

function InteractionPromptRenderer.createPrompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, gui: ScreenGui): () -> ()
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

	local renderedPrompt = {
		part = promptPart,
		attachment = promptParentAttatchment,
		omniDir = isOmniDir,
		shouldUpdatePosition = true
	}

	renderedPrompts[renderedPrompt] = true

	local promptUI = Instance.new("SurfaceGui")
	promptUI.Name = "Prompt"
	promptUI.LightInfluence = 0
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.07)
	frame.Parent = promptUI

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.CornerRadius = UDim.new(0, 8 * SCALE_MULTIPLIER_OLD)
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

	local actionTextFontSize = 30 * SCALE_MULTIPLIER_OLD
	local objectTextFontSize = 15 * SCALE_MULTIPLIER_OLD

	local fontZekton = MAIN_FONT
	local actionTextFont = fontZekton
	local objectTextFont = fontZekton

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.FontFace = actionTextFont
	actionText.TextSize = actionTextFontSize
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = Color3.new(1, 1, 1)
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	actionText.Parent = frame
	table.insert(tweensForButtonHoldEnd, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.fromScale(1, 1)
	objectText.FontFace = objectTextFont
	objectText.TextSize = objectTextFontSize
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	objectText.TextXAlignment = Enum.TextXAlignment.Left
	objectText.Parent = frame

	local tweenInfoStylish = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeInTweens, fadeOutTweens = UIGradientWipe.createFromGuiObjects({actionText, objectText}, tweenInfoStylish)

	for _, tween in fadeInTweens do
		table.insert(tweensForFadeIn, tween)
	end

	for _, tween in fadeOutTweens do
		table.insert(tweensForFadeOut, tween)
	end

	table.insert(tweensForButtonHoldEnd, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))

	table.insert(
		tweensForButtonHoldEnd,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 0.2 })
	)
	table.insert(
		tweensForFadeOut,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 1 })
	)
	table.insert(
		tweensForFadeIn,
		TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 0.2 })
	)

	if prompt.HoldDuration > 0 then
		local roundFrame = Instance.new("Frame")
		roundFrame.Name = "RoundFrame"
		roundFrame.Size = UDim2.fromOffset(45 * SCALE_MULTIPLIER_OLD, 45 * SCALE_MULTIPLIER_OLD)

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
	roundFrameFront.Size = prompt.HoldDuration > 0 and UDim2.fromOffset(40 * SCALE_MULTIPLIER_OLD, 40 * SCALE_MULTIPLIER_OLD) or UDim2.fromOffset(45 * SCALE_MULTIPLIER_OLD, 45 * SCALE_MULTIPLIER_OLD)

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
			icon.Size = UDim2.fromOffset(24 * SCALE_MULTIPLIER_OLD, 24 * SCALE_MULTIPLIER_OLD)
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
		buttonImage.Size = UDim2.fromOffset(25 * SCALE_MULTIPLIER_OLD, 31 * SCALE_MULTIPLIER_OLD)
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
			icon.Size = UDim2.fromOffset(36 * SCALE_MULTIPLIER_OLD, 36 * SCALE_MULTIPLIER_OLD)
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
			buttonText.FontFace = MAIN_FONT
			buttonText.TextSize = 30 * SCALE_MULTIPLIER_OLD
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

	local function updateUIFromPrompt()
		local promptHeight = 60 * SCALE_MULTIPLIER_OLD
		local edgeMargin = 12 * SCALE_MULTIPLIER_OLD -- The gap on the far left (before the icon)
		local iconToTextGap = 50 * SCALE_MULTIPLIER_OLD -- The space the icon occupies (62 - 12)
		
		local actionStr = ClientLanguage.getOrDefault(prompt.ActionText, prompt.ActionText)
		local objectStr = ClientLanguage.getOrDefault(prompt.ObjectText, prompt.ObjectText)
		local hasAction = actionStr ~= ""
		local hasObject = objectStr ~= ""

		-- Why the fuck??????
		local actionTextFetchParam = Instance.new("GetTextBoundsParams")
		actionTextFetchParam.Text = actionStr
		actionTextFetchParam.RichText = actionText.RichText
		actionTextFetchParam.Font = actionTextFont
		actionTextFetchParam.Size = actionTextFontSize

		local actionTextSize = TextService:GetTextBoundsAsync(actionTextFetchParam)

		local objectTextFetchParam = Instance.new("GetTextBoundsParams")
		objectTextFetchParam.Text = objectStr
		objectTextFetchParam.RichText = objectText.RichText
		objectTextFetchParam.Font = objectTextFont
		objectTextFetchParam.Size = objectTextFontSize

		local objectTextSize = TextService:GetTextBoundsAsync(objectTextFetchParam)

		local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
		
		-- Symmetry calculation: Left Margin + Icon Space + Text + Right Margin (same as left)
		local promptWidth = 60 * SCALE_MULTIPLIER_OLD
		if hasAction or hasObject then
			promptWidth = edgeMargin + iconToTextGap + maxTextWidth + edgeMargin
		end

		-- Force alignment to the start of the text area
		actionText.AnchorPoint = Vector2.new(0, 0.5)
		objectText.AnchorPoint = Vector2.new(0, 0.5)
		
		local textXStart = edgeMargin + iconToTextGap

		if hasAction and hasObject then
			actionText.Position = UDim2.new(0, textXStart, 0.35, 0)
			objectText.Position = UDim2.new(0, textXStart, 0.70, 0)
			actionText.Visible = true
			objectText.Visible = true
		elseif hasAction or hasObject then
			local target = hasAction and actionText or objectText
			local hidden = hasAction and objectText or actionText
			
			target.Position = UDim2.new(0, textXStart, 0.5, 0)
			target.Visible = true
			hidden.Visible = false
		else
			actionText.Visible = false
			objectText.Visible = false
		end

		actionText.Text = actionStr
		objectText.Text = objectStr
		
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable

		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		promptUI.CanvasSize = Vector2.new(promptWidth, promptHeight)

		local partWidth = promptWidth / OLD_PIXELS_PER_STUD
		local partHeight = promptHeight / OLD_PIXELS_PER_STUD
		promptPart.Size = Vector3.new(partWidth, partHeight, 0.2)
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

		changedConnection:Disconnect()

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		renderedPrompt.shouldUpdatePosition = false

		task.wait(0.2)

		promptUI.Parent = nil
		promptPart.Parent = nil
	end

	return cleanup
end

function InteractionPromptRenderer.createNonInteractivePrompt(prompt: ProximityPrompt, titleKey: string, subtitleKey: string, gui: ScreenGui): ()
	local tweensForFadeOut: { Tween } = {}
	local tweensForFadeIn: { Tween } = {}
	local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local promptParentAttatchment = prompt.Parent :: Attachment
	local isOmniDir = promptParentAttatchment:GetAttribute(TriggerAttributes.OMNIDIRECTIONAL)

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

	local rendererdPrompt = {
		part = promptPart,
		attachment = promptParentAttatchment,
		omniDir = isOmniDir,
		shouldUpdatePosition = true
	}

	renderedPrompts[rendererdPrompt] = true

	local promptUI = Instance.new("SurfaceGui")
	promptUI.Name = "Prompt"
	promptUI.LightInfluence = 0
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.07)
	frame.Parent = promptUI

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.CornerRadius = UDim.new(0, 8 * SCALE_MULTIPLIER)
	roundedCorner.Parent = frame

	local actionTextFontSize = 20 * SCALE_MULTIPLIER
	local objectTextFontSize = 15 * SCALE_MULTIPLIER

	local fontZekton = MAIN_FONT
	local actionTextFont = fontZekton
	local objectTextFont = fontZekton

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, -0.5)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = frame

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Size = UDim2.fromScale(1, 1)
	actionText.FontFace = actionTextFont
	actionText.TextSize = actionTextFontSize
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = Color3.new(1, 1, 1)
	actionText.TextXAlignment = Enum.TextXAlignment.Center
	actionText.Parent = frame
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Size = UDim2.fromScale(1, 1)
	objectText.FontFace = objectTextFont
	objectText.TextSize = objectTextFontSize
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	objectText.TextXAlignment = Enum.TextXAlignment.Center
	objectText.Parent = frame
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))

	actionText.AnchorPoint = Vector2.new(0.5, 0.5)
	objectText.AnchorPoint = Vector2.new(0.5, 0.5)

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
		local promptHeight = 60 * SCALE_MULTIPLIER
		local edgeMargin = 12 * SCALE_MULTIPLIER -- The gap on the far left (before the icon)
		local iconToTextGap = 0 -- The space the icon occupies (62 - 12)
		
		local actionStr = ClientLanguage.getOrDefault(titleKey, titleKey)
		local objectStr = ClientLanguage.getOrDefault(subtitleKey, subtitleKey)
		local hasAction = actionStr ~= ""
		local hasObject = objectStr ~= ""

		-- Why the fuck??????
		local actionTextFetchParam = Instance.new("GetTextBoundsParams")
		actionTextFetchParam.Text = actionStr
		actionTextFetchParam.RichText = actionText.RichText
		actionTextFetchParam.Font = actionTextFont
		actionTextFetchParam.Size = actionTextFontSize

		local actionTextSize = TextService:GetTextBoundsAsync(actionTextFetchParam)

		local objectTextFetchParam = Instance.new("GetTextBoundsParams")
		objectTextFetchParam.Text = objectStr
		objectTextFetchParam.RichText = objectText.RichText
		objectTextFetchParam.Font = objectTextFont
		objectTextFetchParam.Size = objectTextFontSize

		local objectTextSize = TextService:GetTextBoundsAsync(objectTextFetchParam)

		local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
		
		-- Symmetry calculation: Left Margin + Icon Space + Text + Right Margin (same as left)
		local promptWidth = 60
		if hasAction or hasObject then
			promptWidth = edgeMargin + iconToTextGap + maxTextWidth + edgeMargin
		end

		actionText.Size = UDim2.fromOffset(actionTextSize.X, actionTextSize.Y)
		objectText.Size = UDim2.fromOffset(objectTextSize.X, objectTextSize.Y)

		if hasAction and hasObject then
			actionText.Visible = true
			objectText.Visible = true
		elseif hasAction or hasObject then
			actionText.Visible = hasAction
			objectText.Visible = hasObject
		else
			actionText.Visible = false
			objectText.Visible = false
		end

		actionText.Text = actionStr
		objectText.Text = objectStr
		
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable

		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		promptUI.CanvasSize = Vector2.new(promptWidth, promptHeight)

		local partWidth = promptWidth / NEW_PIXELS_PER_STUD
		local partHeight = promptHeight / NEW_PIXELS_PER_STUD
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

		rendererdPrompt.shouldUpdatePosition = false

		task.wait(0.2)

		promptUI.Parent = nil
		promptPart.Parent = nil
	end

	return cleanup
end

function InteractionPromptRenderer.getScreenGui(): ScreenGui
	local screenGui = PlayerGui:FindFirstChild("InteractionPromptRenderer")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "InteractionPromptRenderer"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

return InteractionPromptRenderer