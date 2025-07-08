--!strict
--[=[
	@class BodyRotationControl
	Controls a body part to rotate towards a position or direction.
]=]
local BodyRotationControl = {}
BodyRotationControl.__index = BodyRotationControl

export type BodyRotationControl = typeof(setmetatable({} :: {
	humanoidRootPart: BasePart,
	targetPosition: Vector3?,
	targetDirection: Vector3?,
	rotationSpeed: number
}, BodyRotationControl))

function BodyRotationControl.new(rootPart: BasePart, speed: number?): BodyRotationControl
	return setmetatable({
		humanoidRootPart = rootPart,
		targetPosition = nil :: Vector3?,
		targetDirection = nil :: Vector3?,
		rotationSpeed = speed or 7
	}, BodyRotationControl)
end

function BodyRotationControl.setSpeed(self: BodyRotationControl, speed: number): ()
	self.rotationSpeed = speed
end

function BodyRotationControl.setRotateTowards(self: BodyRotationControl, toward: Vector3?, speed: number?): ()
	self.targetPosition = toward
	self.targetDirection = nil
	if speed then
		self.rotationSpeed = speed
	end
end

function BodyRotationControl.setRotateToDirection(self: BodyRotationControl, direction: Vector3?, speed: number?): ()
	self.targetDirection = direction
	self.targetPosition = nil
	if speed then
		self.rotationSpeed = speed
	end
end

function BodyRotationControl.update(self: BodyRotationControl, deltaTime: number): ()
	local part = self.humanoidRootPart
	local lookDir: Vector3?
	
	-- Determine look direction based on target type
	if self.targetPosition then
		local origin = Vector3.new(part.Position.X, 0, part.Position.Z)
		local target = Vector3.new(self.targetPosition.X, 0, self.targetPosition.Z)
		lookDir = (target - origin).Unit
	elseif self.targetDirection then
		-- Use the direction directly, but flatten it to Y=0 plane
		lookDir = Vector3.new(self.targetDirection.X, 0, self.targetDirection.Z).Unit
	end
	
	-- Apply rotation if we have a valid look direction
	if lookDir and lookDir.Magnitude > 0 then
		local targetCFrame = CFrame.new(part.Position, part.Position + lookDir)
		part.CFrame = part.CFrame:Lerp(targetCFrame, deltaTime * self.rotationSpeed)
	end
end

return BodyRotationControl