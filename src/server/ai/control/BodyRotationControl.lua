--!strict

--[=[
	@class BodyRotationControl

	Controls a body part to rotate towards a position.
]=]
local BodyRotationControl = {}
BodyRotationControl.__index = BodyRotationControl

export type BodyRotationControl = typeof(setmetatable({} :: {
	humanoidRootPart: BasePart,
	targetPosition: Vector3?,
	rotationSpeed: number
}, BodyRotationControl))

function BodyRotationControl.new(rootPart: BasePart, speed: number?): BodyRotationControl
	return setmetatable({
		humanoidRootPart = rootPart,
		targetPosition = nil :: Vector3?,
		rotationSpeed = speed or 7
	}, BodyRotationControl)
end

function BodyRotationControl.setSpeed(self: BodyRotationControl, speed: number): ()
	self.rotationSpeed = speed
end

function BodyRotationControl.setRotateTowards(self: BodyRotationControl, toward: Vector3?, speed: number?): ()
	self.targetPosition = toward
	if speed then
		self.rotationSpeed = speed
	end
end

function BodyRotationControl.update(self: BodyRotationControl, deltaTime: number): ()
	local targetPosition = self.targetPosition
	if targetPosition then
		local part = self.humanoidRootPart
		local origin = Vector3.new(part.Position.X, 0, part.Position.Z)
		local target = Vector3.new(targetPosition.X, 0, targetPosition.Z)
		local lookDir = (target - origin).Unit
		local targetCFrame = CFrame.new(part.Position, part.Position + Vector3.new(lookDir.X, 0, lookDir.Z))

		part.CFrame = part.CFrame:Lerp(targetCFrame, deltaTime * self.rotationSpeed)
	end
end

return BodyRotationControl