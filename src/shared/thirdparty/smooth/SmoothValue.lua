--!strict

local SmoothDamp = require(script.Parent.SmoothDamp)

--[=[
	@class SmoothValue
]=]
local SmoothValue = {}
SmoothValue.__index = SmoothValue

export type SmoothValue = typeof(setmetatable({} :: {
	value: Vector3,
	goal: Vector3,
	smoothTime: number,
	_smoothDamp: SmoothDamp.SmoothDamp
}, SmoothValue))

function SmoothValue.new(vec3: Vector3, smoothTime: number): SmoothValue
	assert(smoothTime >= 0, "smoothTime must be a positive number")

	return setmetatable({
		value = vec3,
		goal = vec3,
		smoothTime = smoothTime,
		_smoothDamp = SmoothDamp.new()
	}, SmoothValue)
end

function SmoothValue.getMaxSpeed(self: SmoothValue)
	return self._smoothDamp.maxSpeed
end

function SmoothValue.setMaxSpeed(self: SmoothValue, maxSpeed: number)
	self._smoothDamp.maxSpeed = maxSpeed
end

function SmoothValue.update(self: SmoothValue, target: Vector3?): Vector3
	if target then
		self.goal = target
	else
		target = self.goal
	end

	local smoothVec3 = self._smoothDamp:update(self.value, target :: Vector3, self.smoothTime)
	self.value = smoothVec3

	return smoothVec3
end

function SmoothValue.updateAngle(self: SmoothValue, target: Vector3)
	if target then
		self.goal = target
	else
		target = self.goal
	end

	local smoothVec3 = self._smoothDamp:updateAngle(self.value, target, self.smoothTime)
	self.value = smoothVec3

	return smoothVec3
end

return SmoothValue