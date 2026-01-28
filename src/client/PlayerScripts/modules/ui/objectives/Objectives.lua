--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local IndicatorsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.hud.indicator.IndicatorsRenderer)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UITextShadow)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local objectivesUi = playerGui:WaitForChild("Objectives")
local referenceUi = objectivesUi.Root.SafeAreaFrame.Frame.REF

objectivesUi.Enabled = true

local bodyTextsTweensForHide: { [string]: {Tween} } = {}
local bodyTextsTweensForShow: { [string]: {Tween} } = {}

local TWEEN_INFO_QUICK_EXPO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local HEADERS_LAYOUT_ORDERS = {
	["Mission"] = 0,
	["Stealth"] = 1,
	["Loud"] = 2
}

local HEADERS_UI_SETTINGS = {
	["Mission"] = {
		BackgroundColor3 = Color3.fromRGB(155, 66, 171),
		TagImageId = 117168128386109,
		HeaderTextKey = "ui.objectives.mission"
	},
	["Stealth"] = {
		BackgroundColor3 = Color3.fromRGB(60, 157, 208),
		TagImageId = 71498862162050,
		HeaderTextKey = "ui.objectives.stealth"
	},
	["Loud"] = {
		BackgroundColor3 = Color3.fromRGB(177, 50, 50),
		HeaderTextKey = "ui.objectives.loud",
		TagImageId = 117168128386109,
	}
} :: { [string]: { BackgroundColor3: Color3, HeaderTextKey: string, TextColor3: Color3, TagImageId: number }}

local BLACK = Color3.new(0, 0, 0)

local function angleDistanceToOffset(angleDegrees: number, distance: number): UDim2
	local angleRadians = math.rad(angleDegrees)
	local xOffset = math.cos(angleRadians) * distance
	local yOffset = math.sin(angleRadians) * distance
	return UDim2.new(0, xOffset, 0, yOffset)
end

local function createObjectiveUI(headerName: string, ref: typeof(referenceUi), headerColor3: Color3, headerTextKey: string, textColor3: Color3?): typeof(referenceUi)
	local objectiveUiClone = ref:Clone()
	objectiveUiClone.Parent = ref.Parent
	objectiveUiClone.Header.Text = ClientLanguage.getOrDefault(headerTextKey, headerTextKey)
	objectiveUiClone.Header.BackgroundColor3 = headerColor3
	objectiveUiClone.TextLabel.AutomaticSize = Enum.AutomaticSize.Y
	objectiveUiClone.TextLabel.TextWrapped = true

	if textColor3 then
		objectiveUiClone.Header.TextColor3 = textColor3
	end
	
	local headerShadow = objectiveUiClone.Header:Clone()
	headerShadow.Name = objectiveUiClone.Header.Name .. "Shadow"
	headerShadow.Parent = objectiveUiClone.Header.Parent
	local offset = angleDistanceToOffset(45, 2)
	headerShadow.BackgroundColor3 = BLACK
	headerShadow.ZIndex -= 1
	headerShadow.Position = objectiveUiClone.Header.Position + offset
	
	local bodyTextLabel = objectiveUiClone.TextLabel
	local bodyTextShadow = UITextShadow.createTextShadow(bodyTextLabel, nil, 2)

	local gradient = Instance.new("UIGradient")
	gradient.Parent = bodyTextLabel

	-- Visible on LEFT, transparent on RIGHT
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),    -- Visible (left)
		NumberSequenceKeypoint.new(0.5, 0),  -- Visible
		NumberSequenceKeypoint.new(0.6, 1),  -- Transparent
		NumberSequenceKeypoint.new(1, 1)     -- Transparent (right)
	})

	-- Start LEFT (so only transparent part shows)
	gradient.Offset = Vector2.new(-1, 0)

	--

	local gradientShadow = Instance.new("UIGradient")
	gradientShadow.Parent = bodyTextShadow

	-- Visible on LEFT, transparent on RIGHT
	gradientShadow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),    -- Visible (left)
		NumberSequenceKeypoint.new(0.5, 0),  -- Visible
		NumberSequenceKeypoint.new(0.6, 1),  -- Transparent
		NumberSequenceKeypoint.new(1, 1)     -- Transparent (right)
	})

	-- Start LEFT (so only transparent part shows)
	gradientShadow.Offset = Vector2.new(-1, 0)

	-- Animate RIGHT (visible part sweeps across)
	local tweenGradientShow = TweenService:Create(
		gradient,
		TWEEN_INFO_QUICK_EXPO,
		{Offset = Vector2.new(1, 0)}
	)

	local tweenGradientHide = TweenService:Create(
		gradient,
		TWEEN_INFO_QUICK_EXPO,
		{Offset = Vector2.new(-1, 0)}
	)

	local tweenGradientShowShadow = TweenService:Create(
		gradientShadow,
		TWEEN_INFO_QUICK_EXPO,
		{Offset = Vector2.new(1, 0)}
	)

	local tweenGradientHideShadow = TweenService:Create(
		gradientShadow,
		TWEEN_INFO_QUICK_EXPO,
		{Offset = Vector2.new(-1, 0)}
	)

	local transparencyShowTween = TweenService:Create(
		bodyTextLabel, TWEEN_INFO_QUICK_EXPO, { TextTransparency = 0 }
	)

	local transparencyHideTween = TweenService:Create(
		bodyTextLabel, TWEEN_INFO_QUICK_EXPO, { TextTransparency = 1 }
	)

	if not bodyTextsTweensForShow[headerName] then
		bodyTextsTweensForShow[headerName] = {}
	end

	if not bodyTextsTweensForHide[headerName] then
		bodyTextsTweensForHide[headerName] = {}
	end

	table.insert(bodyTextsTweensForShow[headerName], transparencyShowTween)
	table.insert(bodyTextsTweensForShow[headerName], tweenGradientShow)
	table.insert(bodyTextsTweensForShow[headerName], tweenGradientShowShadow)

	table.insert(bodyTextsTweensForHide[headerName], transparencyHideTween)
	table.insert(bodyTextsTweensForHide[headerName], tweenGradientHide)
	table.insert(bodyTextsTweensForHide[headerName], tweenGradientHideShadow)
	
	objectiveUiClone.Visible = false
	return objectiveUiClone
end

local objectiveUiElements: { [string]: typeof(referenceUi) } = {}

for headerName, settings in pairs(HEADERS_UI_SETTINGS) do
	local uiElement = createObjectiveUI(
		headerName,
		referenceUi,
		settings.BackgroundColor3,
		settings.HeaderTextKey,
		settings.TextColor3
	)
	uiElement.LayoutOrder = HEADERS_LAYOUT_ORDERS[headerName] or 999
	objectiveUiElements[headerName] = uiElement
end

referenceUi.Visible = false

local currentObjectives: { [string]: {text: string, tag: string} } = {}
local tagsInstances: { [string]: { [Attachment]: true }} = {}

local function createIndicatorsForTag(tag: string, image: number, color: Color3): ()
	local t
	if tagsInstances[tag] then
		t = tagsInstances[tag]
	else
		t = {}
		tagsInstances[tag] = t
	end
	local attRef = Instance.new("Attachment")
	attRef.Name = "TagIndicator"
	for _, inst in CollectionService:GetTagged(tag) do
		-- TODO: This abomination.
		if inst:IsA("BasePart") then
			local att = attRef:Clone()
			att.Parent = inst
			t[att] = true
			IndicatorsRenderer.addIndicatorAttachment(att, image, color)
		elseif inst:IsA("Tool") and inst:FindFirstChild("Handle") then
			local att = attRef:Clone()
			att.Parent = (inst :: any).Handle
			t[att] = true
			IndicatorsRenderer.addIndicatorAttachment(att, image, color)
		elseif inst:IsA("Model") then
			if inst:FindFirstChildOfClass("Humanoid") and inst:FindFirstChild("HumanoidRootPart") then
				local att = attRef:Clone()
				att.Parent = (inst :: any).HumanoidRootPart
				t[att] = true
				IndicatorsRenderer.addIndicatorAttachment(att, image, color)
			else
				local base = inst:FindFirstChild("Base")
				if not base or not base:IsA("BasePart") then
					continue
				end

				local triggerAtt = inst:FindFirstChild("Trigger", true) -- TODO: Hardcoded af.
				if triggerAtt and triggerAtt:IsA("Attachment") then
					local att = attRef:Clone()
					att.Parent = base
					att.WorldCFrame = triggerAtt.WorldCFrame
					t[att] = true
					IndicatorsRenderer.addIndicatorAttachment(att, image, color)
				else
					local att = attRef:Clone()
					att.Parent = base
					t[att] = true
					IndicatorsRenderer.addIndicatorAttachment(att, image, color)
				end
			end
		end
	end
end

local function removeIndicatorsForTag(tag: string)
	local tagAttachments = tagsInstances[tag]
	
	if not tagAttachments then
		return
	end

	for attachment, _ in pairs(tagAttachments) do
		IndicatorsRenderer.removeIndicatorAttachment(attachment)
	end
	
	tagsInstances[tag] = nil
end

local function updateObjectiveUI(headerName: string, data: {text: string, tag: string})
	local uiElement = objectiveUiElements[headerName]
	if not uiElement then
		warn(`No UI element found for header: {headerName}`)
		return
	end

	if data.tag and data.tag ~= "" then
		local headerSettings = HEADERS_UI_SETTINGS[headerName]
		createIndicatorsForTag(data.tag, headerSettings.TagImageId or 0, headerSettings.BackgroundColor3)
	end
	
	local localizedText = ClientLanguage.getOrDefault(data.text, data.text)
	uiElement.TextLabel.Text = localizedText;
	local shadowTextLabel = (uiElement :: any)[uiElement.TextLabel.Name .. "_Shadow"]
	shadowTextLabel.Text = localizedText;
	(shadowTextLabel:FindFirstChildOfClass("UIGradient") :: UIGradient).Offset = Vector2.new(-1, 0);

	(uiElement.TextLabel:FindFirstChildOfClass("UIGradient") :: UIGradient).Offset = Vector2.new(-1, 0)
	uiElement.Visible = true

	for _, tween in bodyTextsTweensForShow[headerName] do
		tween:Play()
	end
end

local function hideObjectiveUI(headerName: string)
	local uiElement = objectiveUiElements[headerName]

	for _, tween in bodyTextsTweensForHide[headerName] do
		tween:Play()
	end

	task.spawn(function()
		task.wait(1)
		uiElement.Visible = false
	end)
end

TypedRemotes.ClientBoundObjectivesInfo.OnClientEvent:Connect(function(payload)
	for headerName, currentData in pairs(currentObjectives) do
		if not payload[headerName] then
			if currentData.tag and currentData.tag ~= "" then
				removeIndicatorsForTag(currentData.tag)
			end
			
			hideObjectiveUI(headerName)
		end
	end
	
	for headerName, data in pairs(payload) do
		local currentData = currentObjectives[headerName]
		
		if not currentData or
			currentData.text ~= data.text or 
			currentData.tag ~= data.tag then
			
			if currentData and currentData.tag and currentData.tag ~= "" and currentData.tag ~= data.tag then
				removeIndicatorsForTag(currentData.tag)
			end
			
			updateObjectiveUI(headerName, data)
		end
	end

	currentObjectives = payload
end)

return {}