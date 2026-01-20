--!strict

----------------------------------------------------------------------------------------------------------------

local PI = math.pi
local TAU = math.pi * 2

local function deltaAngle(current: number, target: number): number
	local n = (target - current) % TAU
	return (n > PI and (n - TAU) or n)
end

local function deltaAngleVec3(p1: Vector3, p2: Vector3)
	return Vector3.new(deltaAngle(p1.X, p2.X), deltaAngle(p1.Y, p2.Y), deltaAngle(p1.Z, p2.Z))
end

----------------------------------------------------------------------------------------------------------------

--[=[
	@class SmoothDamp

	A module for smooth damping. Orignally created by Stephen Leitnick.
	Original module can be found [here](https://github.com/Sleitnick/AeroGameFramework/blob/3b83b84f3fd8ed4684876594b0e232884f988de7/src/StarterPlayer/StarterPlayerScripts/Aero/Modules/Smooth/SmoothDamp.lua#).
]=]
local SmoothDamp = {}
SmoothDamp.__index = SmoothDamp

export type SmoothDamp = typeof(setmetatable({} :: {
	maxSpeed: number,
	_update: number,
	_velocity: Vector3
}, SmoothDamp))

function SmoothDamp.new(): SmoothDamp
	return setmetatable({
		maxSpeed = math.huge,
		_update = time(),
		_velocity = Vector3.new()
	}, SmoothDamp)
end

function SmoothDamp.update(self: SmoothDamp, current: Vector3, target: Vector3, smoothTime: number): Vector3
	local currentVelocity = self._velocity
	local now = time()
	local deltaTime = (now - self._update)
	smoothTime = math.max(0.0001, smoothTime)

	local num = (2 / smoothTime)
	local num2 = (num * deltaTime)
	local d = (1 / (1 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2))

	local vector = (current - target)
	local vector2 = target

	local maxLength = (self.maxSpeed * smoothTime)
	vector = vector.Magnitude > maxLength and (vector.Unit * maxLength) or vector -- Clamp magnitude.
	target = (current - vector)

	local vector3 = ((currentVelocity + num * vector) * deltaTime)
	currentVelocity = ((currentVelocity - num * vector3) * d)

	local vector4 = (target + (vector + vector3) * d)
	if ((vector2 - current):Dot(vector4 - vector2) > 0) then
		vector4 = vector2
		currentVelocity = ((vector4 - vector2) / deltaTime)
	end

	self._velocity = currentVelocity
	self._update = now

	return vector4
end

function SmoothDamp.updateAngle(self: SmoothDamp, current: Vector3, target: Vector3, smoothTime: number)
	return self:update(current, (current + deltaAngleVec3(current, target)), smoothTime)
end

return SmoothDamp