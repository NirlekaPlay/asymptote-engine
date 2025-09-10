--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local RTween = require(StarterPlayer.StarterPlayerScripts.client.modules.interpolation.RTween)
local WorldPointer = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.WorldPointer)
local localPlayer = Players.LocalPlayer

local DETECTION_METER_IMAGE_GLOW_CONTENT = Content.fromAssetId(132854348499510)
local DETECTION_METER_IMAGE_BACKGROUND_CONTENT = Content.fromAssetId(121436054593975)
local RED = Color3.new(1, 0, 0)

local detectionMeterScreenGui: ScreenGui
local queuedDetectionMeterCalls: { DetectionMeterRenderCall } = {}
local detectionMetersPool: { DetectionMeterObject } = {}

--[=[
	@class DetectionMeterRenderer
]=]
local DetectionMeterRenderer = {}

export type DetectionMeterObject = {
	rootFrame: Frame,
	backgroundMeter: ImageLabel,
	fillMeter: ImageLabel,
	worldPointer: WorldPointer.WorldPointer,
	inUse: boolean,
	removeFromPool: boolean,
}

export type DetectionMeterRenderCall = {
	fillColor: Color3,
	fillTransparency: number,
	fillImageContent: Content,
	susValue: number,
	rotateTowardsWorldPos: Vector3
}

-- TODO: This whole batched and pooled rendering object taken from DebugRenderer
-- should be made into a reuseable module script. But keep this for now.
local function getDetectionMeterInstance(): DetectionMeterObject
	for _, obj in ipairs(detectionMetersPool) do
		if not obj.inUse then
			obj.inUse = true
			obj.rootFrame.Visible = true
			return obj
		end
	end

	local newObj = DetectionMeterRenderer.createDetectionMeter()
	newObj.inUse = true
	table.insert(detectionMetersPool, newObj)
	return newObj
end

local function resetUnusedObjects()
	for i = #detectionMetersPool, 1, -1 do
		local obj = detectionMetersPool[i]
		if obj.removeFromPool then
			table.remove(detectionMetersPool, i)
		elseif not obj.inUse then
			obj.rootFrame.Visible = false
		end
		obj.inUse = false
	end
end

local function getForwardUdim(posUdim: UDim2, rotDeg: number, distance: number): UDim2
	local rotRad = math.rad(rotDeg - 90)
	local direction = Vector2.new(math.cos(rotRad), math.sin(rotRad))

	local xOffset = posUdim.X.Offset + direction.X * distance
	local yOffset = posUdim.Y.Offset + direction.Y * distance

	return UDim2.new(posUdim.X.Scale, xOffset, posUdim.Y.Scale, yOffset)
end

function DetectionMeterRenderer.clearBatch(): ()
	table.clear(queuedDetectionMeterCalls)
end

function DetectionMeterRenderer.renderBatchedCalls(): ()
	resetUnusedObjects()

	for _, renderCall in ipairs(queuedDetectionMeterCalls) do
		local detectionMeter = getDetectionMeterInstance()
		DetectionMeterRenderer.updateDetectionMeter(detectionMeter, renderCall)
	end
end

function DetectionMeterRenderer.renderDetectionMeter(
	fillColor: Color3,
	fillImageContent: Content,
	susValue: number,
	rotateTowardsWorldPos: Vector3,
	fillTransparency: number
): ()
	table.insert(queuedDetectionMeterCalls, {
		fillColor = fillColor,
		susValue = susValue,
		rotateTowardsWorldPos = rotateTowardsWorldPos,
		fillTransparency = fillTransparency,
		fillImageContent = fillImageContent
	})
end

function DetectionMeterRenderer.updateDetectionMeter(
	detectionMeterObject: DetectionMeterObject, renderCallData: DetectionMeterRenderCall
): ()

	local clampedSusValue = math.clamp(renderCallData.susValue, 0, 1)
	detectionMeterObject.worldPointer:setTargetPos(renderCallData.rotateTowardsWorldPos)
	detectionMeterObject.worldPointer:update()
	detectionMeterObject.fillMeter.ImageContent = renderCallData.fillImageContent
	detectionMeterObject.fillMeter.ImageColor3 = renderCallData.fillColor
	detectionMeterObject.fillMeter.ImageTransparency = renderCallData.fillTransparency
	detectionMeterObject.fillMeter.Size = UDim2.fromScale(clampedSusValue, 1)
	task.defer(function()
		detectionMeterObject.rootFrame.Visible = true
	end)

	if renderCallData.susValue == 1 then
		DetectionMeterRenderer.animateMeterAlert(detectionMeterObject, renderCallData)
	end
end

function DetectionMeterRenderer.animateMeterAlert(
	detectionMeterInstance: DetectionMeterObject, renderCallData: DetectionMeterRenderCall
): ()

	local rootFrame = detectionMeterInstance.rootFrame
	local distance = 30
	local udimPos = getForwardUdim(rootFrame.Position, rootFrame.Rotation, distance)
	local tween = RTween.create(Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- "nir, whats with the sudden break of naming convention--"
	-- legacy code, dumbass. this shit is from Godot's Tween.
	-- and also when i programmed this, i used snake_case often. becasue of Godot.
	tween:set_parallel(true)
	tween:tween_instance(detectionMeterInstance.backgroundMeter, {ImageTransparency = 1}, 0.3)
	tween:tween_instance(detectionMeterInstance.fillMeter, {ImageTransparency = 1}, 0.3)
	tween:tween_instance(detectionMeterInstance.rootFrame, {Position = udimPos}, 0.3)
	tween:tween_instance(detectionMeterInstance.fillMeter, {ImageColor3 = RED}, 0.3)
	tween:play()

	-- awful hack alert:
	detectionMeterInstance.removeFromPool = true
	Debris:AddItem(detectionMeterInstance.rootFrame, 0.5)
end

function DetectionMeterRenderer.createDetectionMeter(): DetectionMeterObject
	local rootFrame = Instance.new("Frame")
	rootFrame.BackgroundTransparency = 1
	rootFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- center bottom
	rootFrame.Position = UDim2.fromScale(0.5, 0.5)
	rootFrame.Size = UDim2.fromScale(0.07, 0.5)
	rootFrame.Name = "DetectionMeter"
	rootFrame.Visible = false

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 0.28)
	frame.Parent = rootFrame

	local sizeConstraint = Instance.new("UIAspectRatioConstraint")
	sizeConstraint.AspectRatio = 2.957
	sizeConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	sizeConstraint.DominantAxis = Enum.DominantAxis.Width
	sizeConstraint.Parent = frame

	local backgroundMeterImageLabel = Instance.new("ImageLabel")
	backgroundMeterImageLabel.Name = "Background"
	backgroundMeterImageLabel.BackgroundTransparency = 1
	backgroundMeterImageLabel.ImageTransparency = 0.5
	backgroundMeterImageLabel.ImageContent = DETECTION_METER_IMAGE_BACKGROUND_CONTENT
	backgroundMeterImageLabel.ImageColor3 = Color3.new(0, 0, 0)
	backgroundMeterImageLabel.Size = UDim2.fromScale(1, 1)
	backgroundMeterImageLabel.ScaleType = Enum.ScaleType.Crop
	backgroundMeterImageLabel.ZIndex = 0
	backgroundMeterImageLabel.Parent = frame

	local fillMeterImageLabel = Instance.new("ImageLabel")
	fillMeterImageLabel.Name = "Fill"
	fillMeterImageLabel.BackgroundTransparency = 1
	fillMeterImageLabel.ImageContent = DETECTION_METER_IMAGE_GLOW_CONTENT
	fillMeterImageLabel.ImageColor3 = Color3.new(1, 1, 1)
	fillMeterImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	fillMeterImageLabel.Position = UDim2.fromScale(0.5, 0.5)
	fillMeterImageLabel.Size = UDim2.fromScale(0, 1)
	fillMeterImageLabel.ScaleType = Enum.ScaleType.Crop
	fillMeterImageLabel.ZIndex = 1
	fillMeterImageLabel.Parent = frame

	if not detectionMeterScreenGui then
		detectionMeterScreenGui = DetectionMeterRenderer.createScreenGui()
	end

	rootFrame.Parent = detectionMeterScreenGui

	local detectionMeterData: DetectionMeterObject = {
		rootFrame = rootFrame,
		backgroundMeter = backgroundMeterImageLabel,
		fillMeter = fillMeterImageLabel,
		worldPointer = WorldPointer.new(rootFrame), 
		inUse = false,
		removeFromPool = false
	}

	return detectionMeterData
end

function DetectionMeterRenderer.createScreenGui(): ScreenGui
	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.Name = "DetectionMeters"
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.Parent = localPlayer.PlayerGui

	return newScreenGui
end

return DetectionMeterRenderer