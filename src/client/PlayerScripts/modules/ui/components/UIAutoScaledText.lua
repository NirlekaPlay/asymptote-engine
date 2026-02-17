--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)

local camera = workspace.CurrentCamera

--[=[
	@class UIAutoScaledText
]=]
local UIAutoScaledText = {}

function UIAutoScaledText.fromTextLabel(textLabel: TextLabel, baseResolutionWidth: number, intendedFontSize: number): TextLabel
	local function updateFontSize()
		local viewportSize = camera.ViewportSize
		local scaleFactor = viewportSize.X / baseResolutionWidth
		local newSize = math.round(intendedFontSize * scaleFactor)

		textLabel.TextSize = math.max(newSize, 1)
	end

	local maid = Maid.new()

	maid:giveTask(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFontSize))
	maid:giveTask(textLabel.Destroying:Connect(function()
		maid:doCleaning()
	end))
	maid:giveTask(textLabel.AncestryChanged:Connect(function()
		if not textLabel:IsAncestorOf(game) then
			maid:doCleaning()
		end
	end))

	task.spawn(function()
		-- Race condition bullshit to prevent `1, 1` viewport sizes
		while camera.ViewportSize.X <= 1 do
			camera:GetPropertyChangedSignal("ViewportSize"):Wait()
		end
		updateFontSize()
	end)

	return textLabel
end

return UIAutoScaledText