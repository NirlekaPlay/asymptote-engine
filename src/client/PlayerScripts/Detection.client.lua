--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldPointer = require("./modules/ui/WorldPointer")
local RTween = require("./modules/interpolation/RTween")

local MAX_WOOSH_VOLUME = 3

--[=[
	Defines the actual Gui instance.
]=]
type DetectionMeterUI = {
	rootFrame: Frame,             -- The top-level container
	backgroundBar: ImageLabel,    -- Static background behind the fill
	fillBar: ImageLabel,          -- The bar that visually fills over time
	fillController: CanvasGroup   -- Controls the fill transparency/visibility
}

--[=[
	Defines the detection meter system.
]=]
type DetectionMeterObject = {
	worldPointer: WorldPointer,     -- The WorldPointer instance for rotating to its origin
	meterUi: DetectionMeterUI,      -- Associated UI object
	lastValue: number,              -- Last recorded detection value
	lastRaiseTime: number,          -- Last time (in seconds) the detection value increased
	lastRaiseValue: number,         -- 
	lastUpdateTime: number,         -- Last time (in seconds) the meter was updated
	currentRtween: RTween.RTween,   -- Tween controlling the fill animation
	isVisible: boolean,             -- The meter is visible or not.
	isRaising: boolean,             -- Whether detection value is currently increasing
	doRotate: boolean,              -- Whether WorldPointer should rotate the UI object,
	wooshSound: Sound
}

type WorldPointer = WorldPointer.WorldPointer

--local ALERTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp
local WOOSH_SOUND = ReplicatedStorage.shared.assets.sounds.detection_woosh
WOOSH_SOUND.Looped = true
local REMOTE = require(ReplicatedStorage.shared.network.TypedRemotes).Detection
local DETECTION_GUI = Players.LocalPlayer.PlayerGui:WaitForChild("Detection")
local FRAME_METER_REF = DETECTION_GUI.SusMeter

local activeMeters: { [Model]: DetectionMeterObject } = {}
local characterDiedConnections: { [Model]: RBXScriptConnection } = {}
local random = Random.new(tick())

local function cloneMeterUi(): Frame
	local cloned = FRAME_METER_REF:Clone() :: any -- use any so the typechecker will stfu
	cloned.Visible = true
	cloned.Frame.CanvasGroup.A1.ImageTransparency = 1
	cloned.Frame.A1.ImageTransparency = 1
	cloned.Name = "Cloned"..cloned.Name
	cloned.Parent = DETECTION_GUI

	return cloned
end

local function createMeterGuiObject(ui: Frame): DetectionMeterUI
	local frame = ui:FindFirstChild("Frame") :: Frame
	local canvas = frame:FindFirstChild("CanvasGroup") :: CanvasGroup

	local newDetectionMeterUi = {}
	newDetectionMeterUi.backgroundBar = frame:FindFirstChild("A1") :: ImageLabel
	newDetectionMeterUi.fillBar = canvas:FindFirstChild("A1") :: ImageLabel
	newDetectionMeterUi.fillController = canvas
	newDetectionMeterUi.rootFrame = ui

	return newDetectionMeterUi
end

local function createMeterObject(): DetectionMeterObject
	local newUiInst = createMeterGuiObject(cloneMeterUi())
	local newMeterObject = {}
	newMeterObject.currentRtween = RTween.create(Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	newMeterObject.doRotate = true
	newMeterObject.isRaising = false
	newMeterObject.isVisible = false
	newMeterObject.lastValue = 0
	newMeterObject.lastRaiseTime = 2
	newMeterObject.lastRaiseValue = 0
	newMeterObject.lastUpdateTime = os.clock()
	newMeterObject.meterUi = newUiInst
	newMeterObject.worldPointer = WorldPointer.new(newUiInst.rootFrame)
	newMeterObject.wooshSound = (function()
		local newWooshSound = WOOSH_SOUND:Clone()
		local newPitchSfx = Instance.new("PitchShiftSoundEffect")
		newWooshSound.Parent = newUiInst.rootFrame
		newPitchSfx.Octave = random:NextNumber(1, 1.16)
		newPitchSfx.Parent = newWooshSound
		return newWooshSound
	end)() :: Sound

	return newMeterObject
end

local function getForwardUdim(posUdim: UDim2, rotDeg: number, distance: number): UDim2
	local rotRad = math.rad(rotDeg - 90)
	local direction = Vector2.new(math.cos(rotRad), math.sin(rotRad))

	local xOffset = posUdim.X.Offset + direction.X * distance
	local yOffset = posUdim.Y.Offset + direction.Y * distance

	return UDim2.new(posUdim.X.Scale, xOffset, posUdim.Y.Scale, yOffset)
end

local function animateMeterAlert(currentMeter: DetectionMeterObject)
	currentMeter.wooshSound:Stop()
	local currentMeterUi = currentMeter.meterUi
	local rootFrame = currentMeterUi.rootFrame
	local currentTween = currentMeter.currentRtween
	local distance = 30
	local udimPos = getForwardUdim(rootFrame.Position, rootFrame.Rotation, distance)

	if currentTween.is_playing then
		currentTween:kill()
	end
	currentMeter.doRotate = false -- due to the meter constantly rotating, tweening it up while rotating can make it rotate weirdly. so a lazy solution to this is to not rotate it.
	currentTween:tween_instance(currentMeterUi.backgroundBar, {ImageTransparency = 1}, .3)
	currentTween:tween_instance(currentMeterUi.fillBar, {ImageTransparency = 1}, .3)
	currentTween:tween_instance(currentMeterUi.rootFrame, {Position = udimPos}, .3)
	currentTween:tween_instance(currentMeterUi.fillBar, {ImageColor3 = Color3.new(1, 0, 0)}, .3)
	currentTween:play()
	--ALERTED_SOUND:Play()
end

local function setMeterVisibility(currentMeter: DetectionMeterObject, visible: boolean): ()
	if visible then
		if currentMeter.currentRtween.is_playing then
			currentMeter.currentRtween:kill()
		end
		currentMeter.isVisible = true
		currentMeter.meterUi.fillBar.ImageTransparency = 0
		currentMeter.meterUi.backgroundBar.ImageTransparency = 0.5
		currentMeter.doRotate = true
	else
		currentMeter.isVisible = false
		currentMeter.meterUi.fillBar.ImageTransparency = 1
		currentMeter.meterUi.backgroundBar.ImageTransparency = 1
		currentMeter.doRotate = false
		currentMeter.wooshSound:Stop()
	end
end

local function getOrRegisterNewMeterObjectOf(character: Model): DetectionMeterObject
	local currentMeter = activeMeters[character]
	if not currentMeter then
		local newMeter = createMeterObject()
		setMeterVisibility(newMeter, false)
		newMeter.currentRtween:set_parallel(true)
		activeMeters[character] = newMeter
		currentMeter = newMeter
	end

	return currentMeter
end

local function destroyMeter(character: Model)
	local activeMeter = activeMeters[character]
	activeMeters[character] = nil

	activeMeter.currentRtween:kill()
	activeMeter.meterUi.rootFrame:Destroy()
	characterDiedConnections[character] = nil
end

RunService.RenderStepped:Connect(function(deltaTime)
	for _, meter in pairs(activeMeters) do
		--[[if (os.clock() - meter.lastUpdateTime) > 0.1 then
			setMeterVisibility(meter, false)
		end]]

		if meter.lastRaiseTime > 0 then
			meter.lastRaiseTime -= deltaTime
		end

		if not meter.doRotate then
			continue
		end

		meter.worldPointer:update()
	end
end)

REMOTE.OnClientEvent:Connect(function(suspicionValue: number, character: Model, origin: Vector3)
	--print("received", suspicionValue)
	if not characterDiedConnections[character] then
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		characterDiedConnections[character] = humanoid.Died:Once(function()
			destroyMeter(character)
		end)
	end

	local currentTime = os.clock()
	local currentMeter = getOrRegisterNewMeterObjectOf(character)

	local clampedSusValue = math.clamp(suspicionValue, 0, 1)
	currentMeter.worldPointer:setTargetPos(origin)
	currentMeter.worldPointer:update()
	currentMeter.meterUi.fillController.Size = UDim2.fromScale(clampedSusValue, 1)

	if clampedSusValue > currentMeter.lastValue then
		currentMeter.meterUi.fillBar.ImageColor3 = Color3.new(1, 1, 1)
		currentMeter.lastRaiseTime = 2
		currentMeter.lastRaiseValue = clampedSusValue
		currentMeter.isRaising = true
	elseif clampedSusValue < currentMeter.lastValue then
		currentMeter.meterUi.fillBar.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
		--currentMeter.lastRaiseTime -= (currentTime - lastTime)
		currentMeter.isRaising = false
	end

	currentMeter.lastValue = clampedSusValue

	if currentMeter.isRaising then
		currentMeter.wooshSound.Volume = math.map(clampedSusValue, 0, 1, 0, MAX_WOOSH_VOLUME) -- max woosh volume is 3
	else
		currentMeter.wooshSound.Volume = math.map(currentMeter.lastRaiseTime, 0, 2, 0, currentMeter.lastRaiseValue)
	end

	if not currentMeter.wooshSound.IsPlaying then
		currentMeter.wooshSound:Play()
	end

	if clampedSusValue >= 1 then
		animateMeterAlert(currentMeter)
	end

	local shouldHide = clampedSusValue <= 0 or currentMeter.lastRaiseTime <= 0
	if not shouldHide and not currentMeter.isVisible then
		setMeterVisibility(currentMeter, true)
	elseif shouldHide and currentMeter.isVisible then
		setMeterVisibility(currentMeter, false)
	end

	currentMeter.lastUpdateTime = currentTime
end)