--!strict

local ORIGINAL_NECK_C0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local VERTICAL_FACTOR = 0.6
local HORIZONTAL_FACTOR = 1.5

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
		rotationSpeed = 0.3
	}, LookControl)
end

function LookControl.setLookAtPos(self: LookControl, lookAtPos: Vector3?): ()
	self.lookAtPos = lookAtPos
end

function LookControl.update(self: LookControl): ()
	local character = self.character
	local head = character:FindFirstChild("Head") :: BasePart
	local torso = character:FindFirstChild("Torso") :: BasePart
	local neck = torso:FindFirstChild("Neck") :: Motor6D
	local speed = self.rotationSpeed

	local finalWantedCframe = ORIGINAL_NECK_C0

	if self.lookAtPos then
		local pos = self.lookAtPos
		local distance = (head.CFrame.Position - pos).Magnitude
		local difference = head.CFrame.Y - pos.Y

		local diffUnit = ((head.Position - pos).Unit)
		local torsoLV = torso.CFrame.LookVector

		local angle = CFrame.Angles(
			math.asin(difference / distance) * VERTICAL_FACTOR,
			0,
			diffUnit:Cross(torsoLV).Y * HORIZONTAL_FACTOR
		)

		finalWantedCframe *= angle
	end

	neck.C0 = neck.C0:Lerp(finalWantedCframe, speed / 2)
end

--[=[
	No developers were harmed during the making of this class. (yay?)
	I snatch this from a very old project, thankfully past me has suffered
	enough so the suffering will not pass to me.

	I'm proud of this class.

	- Nir
]=]

--[=[
	-- If you want to test it :D
	-- Alice

	local currentCamera = workspace.CurrentCamera
	currentCamera:SetAttribute("VerFactor", VERTICAL_FACTOR)
	currentCamera:SetAttribute("HorFactor", HORIZONTAL_FACTOR)
	currentCamera:GetAttributeChangedSignal("VerFactor"):Connect(function()
		VERTICAL_FACTOR = currentCamera:GetAttribute("VerFactor")
	end)

	currentCamera:GetAttributeChangedSignal("HorFactor"):Connect(function()
		HORIZONTAL_FACTOR = currentCamera:GetAttribute("HorFactor")
	end)
]=]

return LookControl