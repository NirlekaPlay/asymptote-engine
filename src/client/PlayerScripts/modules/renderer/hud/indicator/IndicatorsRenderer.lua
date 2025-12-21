--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local SCREEN_GUI_NAME = "Indicators"
local DEFAULT_SIZE = UDim2.new(0.038, 0, 0.038, 0)
local MIDDLE_ANCHOR_POINT = Vector2.new(0.5, 0.5)
local MIDDLE_POSITION = UDim2.new(0.5, 0, 0.5, 0)

local HIDE_TIME = 0.5
local TWEEN_INFO_QUICK = TweenInfo.new(HIDE_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)

local worldIndicatorsSet: { [Indicator]: true } = {}

--[=[
	@class IndicatorsManagers

	All credits goes to PersonifiedPizza :)
]=]
local IndicatorsRenderer = {}

export type Indicator = {
	attachment: Attachment,
	ui: Frame,
	tweensForShow: { Tween },
	tweensForHide: { Tween }
}

local function angleDistanceToOffset(angleDegrees: number, distance: number): UDim2 -- this is repeated 3 times already.
	local angleRadians = math.rad(angleDegrees)
	local xOffset = math.cos(angleRadians) * distance
	local yOffset = math.sin(angleRadians) * distance

	-- Return as UDim2 with scale 0 and offset as pixels
	return UDim2.new(0, xOffset, 0, yOffset)
end

function IndicatorsRenderer.addIndicatorAttachment(attachment: Attachment, image: number?, color: Color3?): ()
	local indicatorUi = IndicatorsRenderer.createNewIndicatorUi(image, color)
	indicatorUi.Parent = IndicatorsRenderer.getScreenGui()

	local newIndicator: Indicator = {
		attachment = attachment,
		ui = indicatorUi,
		tweensForShow = {
			TweenService:Create((indicatorUi :: any).IconImage, TWEEN_INFO_QUICK, { ImageTransparency = 0 }),
			TweenService:Create((indicatorUi :: any).IconImage_Shadow, TWEEN_INFO_QUICK, { ImageTransparency = 0 })
		},
		tweensForHide = {
			TweenService:Create((indicatorUi :: any).IconImage, TWEEN_INFO_QUICK, { ImageTransparency = 1 }),
			TweenService:Create((indicatorUi :: any).IconImage_Shadow, TWEEN_INFO_QUICK, { ImageTransparency = 1 })
		}
	}

	for _, tween in newIndicator.tweensForShow do
		tween:Play()
	end

	worldIndicatorsSet[newIndicator] = true
end

function IndicatorsRenderer.removeIndicator(indicator: Indicator): ()
	print(debug.traceback())
	task.spawn(function()
		for _, tween in indicator.tweensForHide do
			tween:Play()
		end

		task.wait(HIDE_TIME)

		worldIndicatorsSet[indicator] = nil
		print("removed")
		indicator.ui:Destroy()
		indicator.attachment:Destroy()
	end)
end

function IndicatorsRenderer.removeIndicatorAttachment(attachment: Attachment): ()
	for indicator in worldIndicatorsSet do
		if indicator.attachment == attachment then
			IndicatorsRenderer.removeIndicator(indicator)
			return
		end
	end
end

function IndicatorsRenderer.update(): ()
	IndicatorsRenderer.clearInvalidIndicators()
	IndicatorsRenderer.updateIndicatorsUiPositions()
end

function IndicatorsRenderer.clearInvalidIndicators(): ()
	if next(worldIndicatorsSet) == nil then
		return
	end

	local indicatorsToRemove: { [Indicator]: true } = {}

	for indicator in worldIndicatorsSet do
		if IndicatorsRenderer.isIndicatorInvalid(indicator) then
			indicatorsToRemove[indicator] = true
		end
	end

	for indicator in indicatorsToRemove do
		IndicatorsRenderer.removeIndicator(indicator)
	end
end

function IndicatorsRenderer.updateIndicatorsUiPositions(): ()
	if next(worldIndicatorsSet) == nil then
		return
	end

	local viewportX = camera.ViewportSize.X
	local viewportY = camera.ViewportSize.Y
	
	local firstEntry = next(worldIndicatorsSet, nil) :: Indicator
	local bufferSize = firstEntry.ui.AbsoluteSize.X
	
	local maxBoundsX = viewportX - (bufferSize * 2)
	local maxBoundsY = viewportY - (bufferSize * 2)
	
	local camCFrame = camera.CFrame
	local screenHypotenuse = math.sqrt( (maxBoundsX / 2) ^ 2 + (maxBoundsY / 2) ^ 2 )

	for indicator in worldIndicatorsSet do
		local indicatorUI = indicator.ui
		if indicatorUI.Visible == false then
			continue
		end

		local position = indicator.attachment.WorldPosition

		local screenPosition3d, onScreen = camera:WorldToViewportPoint(position)

		local xPosition = math.clamp(screenPosition3d.X, bufferSize, viewportX - bufferSize)
		local yPosition = math.clamp(screenPosition3d.Y, bufferSize, viewportY - bufferSize)

		if (xPosition == screenPosition3d.X) and (yPosition == screenPosition3d.Y) and onScreen then
			-- Handled at the end
		else
			local worldDirection = position - camCFrame.Position
			local relativeDirection = camCFrame:VectorToObjectSpace(worldDirection)
			local relativeDirection2D = Vector2.new(relativeDirection.X, relativeDirection.Y).Unit

			local testScreenPoint = relativeDirection2D * screenHypotenuse
			
			local screenPoint
			if math.abs(testScreenPoint.Y) > maxBoundsY/2 then
				screenPoint = relativeDirection2D * math.abs(maxBoundsY/2/relativeDirection2D.Y)
			else
				screenPoint = relativeDirection2D * math.abs(maxBoundsX/2/relativeDirection2D.X)
			end
			
			xPosition = viewportX / 2 + screenPoint.X
			yPosition = viewportY / 2 - screenPoint.Y
		end
		
		indicatorUI.Position = UDim2.fromOffset(xPosition, yPosition)
	end
end

function IndicatorsRenderer.isIndicatorInvalid(indicator: Indicator): boolean
	if not indicator.attachment then
		return true
	end

	if not indicator.attachment:IsDescendantOf(workspace) then
		return true
	end

	return false
end

function IndicatorsRenderer.createNewIndicatorUi(image: number?, color: Color3?): Frame
	local newMainFrame = Instance.new("Frame")
	newMainFrame.AnchorPoint = MIDDLE_ANCHOR_POINT
	newMainFrame.Size = DEFAULT_SIZE
	newMainFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	newMainFrame.BackgroundTransparency = 1
	newMainFrame.Name = "MainFrame"
	do
		local newIconImage = Instance.new("ImageLabel")
		if image then
			newIconImage.ImageContent = Content.fromAssetId(image)
		end
		if color then
			newIconImage.ImageColor3 = color
		end
		newIconImage.AnchorPoint = MIDDLE_ANCHOR_POINT
		newIconImage.Position = MIDDLE_POSITION
		newIconImage.BackgroundTransparency = 1
		newIconImage.ImageTransparency = 1
		newIconImage.Size = UDim2.fromScale(0.60, 0.60)
		newIconImage.Name = "IconImage"
		newIconImage.Parent = newMainFrame

		local iconImageShadow = newIconImage:Clone()
		iconImageShadow.Name ..= "_Shadow"
		iconImageShadow.ZIndex -= 1
		iconImageShadow.ImageColor3 = Color3.new(0, 0, 0)
		iconImageShadow.Position = iconImageShadow.Position + angleDistanceToOffset(45, 2.5)
		iconImageShadow.Parent = newMainFrame
	end

	return newMainFrame
end

function IndicatorsRenderer.getScreenGui(): ScreenGui
	local existing = playerGui:FindFirstChild(SCREEN_GUI_NAME)
	if not existing then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = SCREEN_GUI_NAME
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

		return screenGui
	end

	return existing :: ScreenGui
end

return IndicatorsRenderer