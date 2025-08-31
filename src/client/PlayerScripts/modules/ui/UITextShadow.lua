--!strict

local DEFAULT_SHADOW_ANGLE_DEGREES = 45 -- bottom right
local DEFAULT_SHADOW_DISTANCE = 5
local DEFAULT_SHADOW_COLOR = Color3.new(0, 0, 0) -- black
local DEFAULT_SHADOW_TRANSPARENCY = 0.3

--[=[
	@class UITextShadow
	
	This module creates a shadow effect for
	[TextLabels](https://create.roblox.com/docs/reference/engine/classes/TextLabel).
]=]
local UITextShadow = {}

--[=[
	Convert angle (in degrees) and distance to UDim2 offset.
]=]
local function angleDistanceToOffset(angleDegrees: number, distance: number): UDim2
	local angleRadians = math.rad(angleDegrees)
	local xOffset = math.cos(angleRadians) * distance
	local yOffset = math.sin(angleRadians) * distance

	-- Return as UDim2 with scale 0 and offset as pixels
	return UDim2.new(0, xOffset, 0, yOffset)
end

--[=[
	Creates and returns a new TextLabel that acts as a shadow
	behind the front TextLabel.
]=]
function UITextShadow.createTextShadow(
	frontText: TextLabel, 
	angleDegrees: number?, 
	distance: number?, 
	shadowColor: Color3?, 
	shadowTransparency: number?
): TextLabel

	angleDegrees = angleDegrees or DEFAULT_SHADOW_ANGLE_DEGREES
	distance = distance or DEFAULT_SHADOW_DISTANCE
	shadowColor = shadowColor or DEFAULT_SHADOW_COLOR
	shadowTransparency = shadowTransparency or DEFAULT_SHADOW_TRANSPARENCY

	local shadowText = frontText:Clone()
	shadowText.Name = frontText.Name .. "_Shadow"
	shadowText.TextColor3 = shadowColor
	shadowText.TextTransparency = shadowTransparency
	shadowText.ZIndex = frontText.ZIndex - 1  -- ensure shadow is behind

	local offset = angleDistanceToOffset(angleDegrees, distance)
	shadowText.Position = frontText.Position + offset

	shadowText.Parent = frontText.Parent

	return shadowText
end

--[=[
	Updates the shadow TextLabel with the front text. Note that this does not
	update the shadow's position as well.
]=]
function UITextShadow.updateShadowProperties(frontText: TextLabel, shadowText: TextLabel): ()
	shadowText.Text = frontText.Text
	shadowText.Font = frontText.Font
	shadowText.TextSize = frontText.TextSize
	shadowText.TextScaled = frontText.TextScaled
	shadowText.TextWrapped = frontText.TextWrapped
	shadowText.Size = frontText.Size
end

return UITextShadow