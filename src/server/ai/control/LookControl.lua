--!strict

local ORIGINAL_NECK_C0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local DEFAULT_ROTATION_SPEED = 7
local VERTICAL_FACTOR = 0.6
local HORIZONTAL_FACTOR = 1
local ADJUSTMENT_MODE = false
local ADJUSTMENT_MODE_VER_FACTOR_ATTRIBUTE_NAME = "LookControlVerFactor"
local ADJUSTMENT_MODE_HOR_FACTOR_ATTRIBUTE_NAME = "LookControlHorFactor"

--[=[
	@class LookControl

	Controls an Agent's head to look at a specified position.
	Note that this only works with R6 rigs.
]=]
local LookControl = {}
LookControl.__index = LookControl

export type LookControl = typeof(setmetatable({} :: {
	character: Model,
	lookAtPos: Vector3?,
	rotationSpeed: number
}, LookControl))

function LookControl.new(character: Model): LookControl
	return setmetatable({
		character = character,
		lookAtPos = nil :: Vector3?,
		rotationSpeed = DEFAULT_ROTATION_SPEED
	}, LookControl)
end

function LookControl.setLookAtPos(self: LookControl, lookAtPos: Vector3?): ()
	self.lookAtPos = lookAtPos
end

function LookControl.update(self: LookControl, deltaTime: number): ()
	local character = self.character
	local head = character:FindFirstChild("Head") :: BasePart
	local torso = character:FindFirstChild("Torso") :: BasePart
	local neck = torso:FindFirstChild("Neck") :: Motor6D

	local finalWantedCframe = ORIGINAL_NECK_C0

	if self.lookAtPos then
		local pos = self.lookAtPos
		local diff = head.Position - pos
		local distance = diff.Magnitude
		local diffUnit = diff.Unit
		local torsoLV = torso.CFrame.LookVector

		finalWantedCframe *= CFrame.Angles(
			math.asin((head.CFrame.Y - pos.Y) / distance) * VERTICAL_FACTOR,
			0,
			diffUnit:Cross(torsoLV).Y * HORIZONTAL_FACTOR
		)
	end

	local alpha = 1 - math.exp(-self.rotationSpeed * deltaTime)
	neck.C0 = neck.C0:Lerp(finalWantedCframe, alpha)
end

if ADJUSTMENT_MODE then
	-- If you want to test it :D (*adjust)
	-- Alice
	-- Modified by Nirleka

	warn("LookControl adjustment mode enabled. Configure the attributes in the current camera.")
	local currentCamera = workspace.CurrentCamera
	currentCamera:SetAttribute(ADJUSTMENT_MODE_VER_FACTOR_ATTRIBUTE_NAME, VERTICAL_FACTOR)
	currentCamera:SetAttribute(ADJUSTMENT_MODE_HOR_FACTOR_ATTRIBUTE_NAME, HORIZONTAL_FACTOR)
	currentCamera:GetAttributeChangedSignal(ADJUSTMENT_MODE_VER_FACTOR_ATTRIBUTE_NAME):Connect(function()
		VERTICAL_FACTOR = currentCamera:GetAttribute(ADJUSTMENT_MODE_VER_FACTOR_ATTRIBUTE_NAME)
	end)

	currentCamera:GetAttributeChangedSignal(ADJUSTMENT_MODE_HOR_FACTOR_ATTRIBUTE_NAME):Connect(function()
		HORIZONTAL_FACTOR = currentCamera:GetAttribute(ADJUSTMENT_MODE_HOR_FACTOR_ATTRIBUTE_NAME)
	end)
end

--[=[
	No developers were harmed during the making of this class. (yay?)
	I snatch this from a very old project, thankfully past me has suffered
	enough so the suffering will not pass to me.

	I'm proud of this class.

	- Nir
]=]

return LookControl