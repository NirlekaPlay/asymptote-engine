--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DetectionMeterRenderer = require(script.Parent.DetectionMeterRenderer)
local DetectionPayload = require(ReplicatedStorage.shared.network.DetectionPayload)

local detectionWooshSoundPerUuid: { [string]: Sound } = {}
local detectionDataPerUuid: { [string]: ExtendedDetectionData } = {}

local DETECTION_METER_IMAGE_GLOW_CONTENT = Content.fromAssetId(132854348499510)
local DETECTION_METER_IMAGE_BACKGROUND_CONTENT = Content.fromAssetId(121436054593975)
local WOOSH_SOUND = ReplicatedStorage.shared.assets.sounds.detection_woosh
local WOOSH_MIN_PICH = 1
local WOOSH_MAX_PITH = 1.16
local WOOSH_MAX_VOL = 3
local RANDOM = Random.new(os.clock())
local WHITE = Color3.new(1, 1, 1)
local DARK_GRAY = Color3.new(0.5, 0.5, 0.5)

--[=[
	@class DetectionMeter
]=]
local DetectionMeter = {}

export type ExtendedDetectionData = {
	detectionData: DetectionPayload.DetectionData,
	hideTimer: number,
	lastRaiseValue: number,
	lastSusValue: number,
	isRaising: boolean
}

function DetectionMeter.addOrUpdateNpcsDetectionValue(detectionData: DetectionPayload.DetectionData): ()
	local prevData = detectionDataPerUuid[detectionData.uuid]

	local isRaising = prevData and (detectionData.detectionValue > prevData.detectionData.detectionValue) or false
	local lastRaiseValue

	if prevData then
		if prevData.isRaising and not isRaising then
			lastRaiseValue = prevData.detectionData.detectionValue
		else
			lastRaiseValue = prevData.lastRaiseValue
		end
	else
		lastRaiseValue = detectionData.detectionValue
	end

	local newExtendedDetectionData: ExtendedDetectionData = {
		detectionData = detectionData,
		hideTimer = prevData and prevData.hideTimer or 2,
		lastRaiseValue = lastRaiseValue,
		lastSusValue = prevData and prevData.detectionData.detectionValue or detectionData.detectionValue,
		isRaising = isRaising
	}

	detectionDataPerUuid[detectionData.uuid] = newExtendedDetectionData
end

function DetectionMeter.render(deltaTime: number): ()
	DetectionMeter.clearInvalidNpcs()
	DetectionMeter.doRender(deltaTime)
end

function DetectionMeter.doRender(deltaTime: number): ()
	for uuid, detectionData in pairs(detectionDataPerUuid) do
		DetectionMeter.updateDetectionMeter(detectionData, deltaTime)
	end
end

function DetectionMeter.updateDetectionMeter(extDetectionData: ExtendedDetectionData, deltaTime: number): ()
	local detectionData = extDetectionData.detectionData

	extDetectionData.hideTimer = extDetectionData.isRaising and 2 or extDetectionData.hideTimer - deltaTime

	local charPos = (detectionData.character.PrimaryPart :: BasePart).Position
	local clampedSusValue = math.clamp(detectionData.detectionValue, 0, 1)
	local shouldHide = clampedSusValue <= 0 or extDetectionData.hideTimer <= 0

	local fillColor = extDetectionData.isRaising and WHITE or DARK_GRAY
	local fillTransparency = extDetectionData.isRaising and 0 or 0.5
	local fillImageContent = extDetectionData.isRaising
		and DETECTION_METER_IMAGE_GLOW_CONTENT
		or DETECTION_METER_IMAGE_BACKGROUND_CONTENT

	DetectionMeter.updateWooshSound(extDetectionData)

	if not shouldHide then
		if clampedSusValue == 1 then
			DetectionMeter.cleanupNpc(detectionData.uuid)
		end

		DetectionMeterRenderer.renderDetectionMeter(fillColor, fillImageContent, clampedSusValue, charPos, fillTransparency)
	end
end

function DetectionMeter.updateWooshSound(extDetectionData: ExtendedDetectionData): ()
	local wooshSound = DetectionMeter.getWooshSound(extDetectionData.detectionData.uuid)
	local clampedSusValue = math.clamp(extDetectionData.detectionData.detectionValue, 0, 1)
	if not wooshSound.IsPlaying then
		wooshSound:Play()
	end

	if extDetectionData.isRaising then
		wooshSound.Volume = math.map(clampedSusValue, 0, 1, 0, WOOSH_MAX_VOL) -- max woosh volume is 3
	else
		wooshSound.Volume = math.map(extDetectionData.hideTimer, 0, 2, 0, extDetectionData.lastRaiseValue)
	end

	if extDetectionData.detectionData.detectionValue == 1 then
		wooshSound:Destroy()
	end
end

--

function DetectionMeter.clearInvalidNpcs(): ()
	for uuid, extDetectionData in pairs(detectionDataPerUuid) do
		if DetectionMeter.isNpcInvalid(extDetectionData.detectionData) then
			DetectionMeter.cleanupNpc(uuid)
		end
	end
end

function DetectionMeter.cleanupNpc(uuid: string): ()
	detectionDataPerUuid[uuid] = nil
	if detectionWooshSoundPerUuid[uuid] then
		detectionWooshSoundPerUuid[uuid]:Destroy()
	end
end

function DetectionMeter.isNpcInvalid(detectionData: DetectionPayload.DetectionData): boolean
	local character = detectionData.character
	if not character then
		return true
	end

	if not character:IsDescendantOf(workspace) then
		return true
	end

	if not character.PrimaryPart then
		return true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return true
	end

	if humanoid.Health <= 0 then
		return true
	end

	return false
end

--

function DetectionMeter.getWooshSound(uuid: string): Sound
	local wooshSound = detectionWooshSoundPerUuid[uuid]
	if not wooshSound then
		wooshSound = DetectionMeter.createWooshSound()
		detectionWooshSoundPerUuid[uuid] = wooshSound
	end

	return wooshSound
end

function DetectionMeter.createWooshSound(): Sound
	local wooshSound = WOOSH_SOUND:Clone()
	wooshSound.Looped = true
	wooshSound.Parent = workspace
	local newPitchSfx = Instance.new("PitchShiftSoundEffect")
	newPitchSfx.Octave = RANDOM:NextNumber(WOOSH_MIN_PICH, WOOSH_MAX_PITH)
	newPitchSfx.Parent = wooshSound

	return wooshSound
end

return DetectionMeter