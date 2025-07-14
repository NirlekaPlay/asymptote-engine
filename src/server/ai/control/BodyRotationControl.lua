--!nonstrict

--[=[
	@class BodyRotationControl

	Controls a body part to rotate towards a position or direction.
]=]
local BodyRotationControl = {}
BodyRotationControl.__index = BodyRotationControl

export type BodyRotationControl = typeof(setmetatable({} :: {
	character: Model,
	lastPos: Vector3,
	targetDirection: Vector3?,
	rotationSpeed: number
}, BodyRotationControl))

function BodyRotationControl.new(character: Model, speed: number?): BodyRotationControl
	return setmetatable({
		character = character,
		targetDirection = nil :: Vector3?,
		rotationSpeed = speed or 7,
		lastPos = character.HumanoidRootPart.Position
	}, BodyRotationControl)
end

function BodyRotationControl.setSpeed(self: BodyRotationControl, speed: number): ()
	self.rotationSpeed = speed
end

function BodyRotationControl.setRotateTowards(self: BodyRotationControl, toward: Vector3?, speed: number?): ()
	if toward then
		local part = self.character.HumanoidRootPart
		local origin = Vector3.new(part.Position.X, 0, part.Position.Z)
		local target = Vector3.new(toward.X, 0, toward.Z)
		self.targetDirection = (target - origin).Unit
	else
		self.targetDirection = nil
	end
	if speed then
		self.rotationSpeed = speed
	end
end

function BodyRotationControl.setRotateToDirection(self: BodyRotationControl, direction: Vector3?, speed: number?): ()
	if direction then
		self.targetDirection = Vector3.new(direction.X, 0, direction.Z).Unit
	else
		self.targetDirection = nil
	end
	if speed then
		self.rotationSpeed = speed
	end
end

function BodyRotationControl.update(self: BodyRotationControl, deltaTime: number): ()
	if self:isMoving() then
		return
	end

	if self.targetDirection then
		if not (self.targetDirection.Magnitude > 0) then
			return
		end
		local part = self.character.HumanoidRootPart
		local targetCFrame = CFrame.new(part.Position, part.Position + self.targetDirection)
		part.CFrame = part.CFrame:Lerp(targetCFrame, deltaTime * self.rotationSpeed)
	end
end

function BodyRotationControl.isMoving(self: BodyRotationControl): boolean
	local humanoidRootPart: BasePart? = self.character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false
	end
	-- turns out, MoveDirection doesnt even get fucking updated.
	-- so we need to do this terribleness.
	-- and also since this control only rotates on Y axis, why bother with Y axis changes?
	-- but hey, if it works, IT WORKS.
	local curPos = humanoidRootPart.Position
	curPos = Vector3.new(curPos.X, 0, curPos.Z)
	local lastPos = self.lastPos
	lastPos = Vector3.new(lastPos.X, 0, lastPos.Z)
	self.lastPos = self.character.HumanoidRootPart.Position
	return (curPos - lastPos).Magnitude > 1e-6
end

return BodyRotationControl