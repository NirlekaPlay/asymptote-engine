--!strict

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)

local DEFAULT_ALWAYS_ON_TOP = true
local DEFAULT_LIGHT_INFLUENCE = 1
local DEFAULT_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local DEFAULT_SHADOW_COLOR = Color3.fromRGB(0, 0, 0)

local ATTRIBUTE_ALWAYS_ON_TOP = "AlwaysOnTop"
local ATTRIBUTE_LIGHT_INFLUENCE = "LightInfluence"
local ATTRIBUTE_CONTENT = "Content"
local ATTRIBUTE_TEXT_COLOR = "TextColor"
local ATTRIBUTE_SHADOW_COLOR = "ShadowColor"

local UNLOCALIZED_STRING_TEXT = "UNLOCALIZED_STRING"

local localPlayer = Players.LocalPlayer
local surfaceTextScreenGui: ScreenGui

local SurfaceText = {}

function SurfaceText.createFromPart(part: BasePart): ()
	local newSurfaceGui = Instance.new("SurfaceGui")
	newSurfaceGui.AlwaysOnTop = SurfaceText.getAttributeOrDefault(part, ATTRIBUTE_ALWAYS_ON_TOP, DEFAULT_ALWAYS_ON_TOP)
	newSurfaceGui.LightInfluence = SurfaceText.getAttributeOrDefault(part, ATTRIBUTE_LIGHT_INFLUENCE, DEFAULT_LIGHT_INFLUENCE)
	newSurfaceGui.PixelsPerStud = 20
	newSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	newSurfaceGui.Adornee = part

	local newTextLabel = Instance.new("TextLabel")
	newTextLabel.Size = UDim2.fromScale(1, 1)
	newTextLabel.FontFace = Font.fromName("Zekton")

	local contentKey = SurfaceText.getAttributeOrDefault(part, ATTRIBUTE_CONTENT, UNLOCALIZED_STRING_TEXT)
	local localizedText = SurfaceText.getLocalizedString(contentKey) or UNLOCALIZED_STRING_TEXT
	newTextLabel.Text = localizedText

	newTextLabel.TextColor3 = SurfaceText.getAttributeOrDefault(part, ATTRIBUTE_TEXT_COLOR, DEFAULT_TEXT_COLOR)
	newTextLabel.TextScaled = true
	newTextLabel.BackgroundTransparency = 1
	newTextLabel.Parent = newSurfaceGui

	local shadowColor = SurfaceText.getAttributeOrDefault(part, ATTRIBUTE_SHADOW_COLOR, DEFAULT_SHADOW_COLOR)
	UITextShadow.createTextShadow(newTextLabel, nil, nil, shadowColor, 0.3)

	newSurfaceGui.Parent = SurfaceText.getScreenGui()
end

function SurfaceText.getScreenGui(): ScreenGui
	if surfaceTextScreenGui then
		return surfaceTextScreenGui
	end

	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.Name = "SurfaceTexts"
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.Parent = localPlayer.PlayerGui

	surfaceTextScreenGui = newScreenGui

	return surfaceTextScreenGui
end

function SurfaceText.getLocalizedString(keyStr: string): string
	return ClientLanguage.getOrDefault(keyStr, keyStr)
end

function SurfaceText.getAttributeOrDefault<T>(inst: Instance, attribute: string, default: T): T
	local get = inst:GetAttribute(attribute)
	if get == nil then
		return default
	else
		return get
	end
end

return SurfaceText