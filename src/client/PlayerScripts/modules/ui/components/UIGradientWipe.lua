--!strict

local TweenService = game:GetService("TweenService")

local GRADIENT_WIPE_NUM_SEQ = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.6, 1),
	NumberSequenceKeypoint.new(1, 1)
})

--[=[
	@class UIGradientWipe
]=]
local UIGradientWipe = {}

function UIGradientWipe.createFromGuiObjects(guiObjects: {GuiObject}, tweenInfo: TweenInfo): ({Tween}, {Tween})
	local showTweens: {Tween} = {}
	local hideTweens: {Tween} = {}

	for _, target in guiObjects do
		local gradient = Instance.new("UIGradient")
		gradient.Transparency = GRADIENT_WIPE_NUM_SEQ
		gradient.Offset = Vector2.new(-1, 0)
		gradient.Parent = target

		table.insert(showTweens, TweenService:Create(gradient, tweenInfo, {Offset = Vector2.new(1, 0)}))
		table.insert(hideTweens, TweenService:Create(gradient, tweenInfo, {Offset = Vector2.new(-1, 0)}))
		
		--[[
		-- Why.
		if target:IsA("TextLabel") or target:IsA("TextBox") or target:IsA("TextButton") then
			table.insert(showTweens, TweenService:Create(target, tweenInfo, {TextTransparency = 0}))
			table.insert(hideTweens, TweenService:Create(target, tweenInfo, {TextTransparency = 1}))
		end]]
	end

	return showTweens, hideTweens
end

return UIGradientWipe