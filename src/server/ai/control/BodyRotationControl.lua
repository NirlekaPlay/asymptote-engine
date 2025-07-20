--!nonstrict

local PathNavigation = require("../navigation/PathNavigation")
local DEFAULT_ROTATION_SPEED = 5.5
local MAX_ROTATION_COOLDOWN = 0.25 -- How many seconds it takes after the Agent was moving before we can rotate again

--[=[
	@class BodyRotationControl

	Controls a body part to rotate towards a position or direction.
]=]
local BodyRotationControl = {}
BodyRotationControl.__index = BodyRotationControl

export type BodyRotationControl = typeof(setmetatable({} :: {
	character: Model,
	pathNav: PathNavigation.PathNavigation, -- to avoid circular dependency
	lastPos: Vector3,
	targetDirection: Vector3?,
	rotationSpeed: number,
	rotationCooldown: number
}, BodyRotationControl))

function BodyRotationControl.new(character: Model, pathNav: PathNavigation.PathNavigation, speed: number?): BodyRotationControl
	return setmetatable({
		character = character,
		pathNav = pathNav,
		targetDirection = nil :: Vector3?,
		rotationSpeed = speed or DEFAULT_ROTATION_SPEED,
		rotationCooldown = MAX_ROTATION_COOLDOWN,
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
		self.rotationCooldown = MAX_ROTATION_COOLDOWN
		return
	end

	if self.rotationCooldown > 0 then
		self.rotationCooldown -= deltaTime
		return
	end

	local direction = self.targetDirection
	if not direction or direction.Magnitude == 0 then
		return
	end

	local rootPart = self.character.HumanoidRootPart
	local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + direction)
	rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, deltaTime * self.rotationSpeed)
end

function BodyRotationControl.isMoving(self: BodyRotationControl): boolean
	if self.pathNav:isMoving() then
		return true
	end

	local humanoidRootPart: BasePart? = self.character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false
	end

	local curPos = humanoidRootPart.Position
	curPos = Vector3.new(curPos.X, 0, curPos.Z)
	local lastPos = self.lastPos
	lastPos = Vector3.new(lastPos.X, 0, lastPos.Z)
	self.lastPos = self.character.HumanoidRootPart.Position
	return (curPos - lastPos).Magnitude > 1e-6
end

return BodyRotationControl