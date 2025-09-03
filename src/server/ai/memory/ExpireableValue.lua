--!strict

--[=[
	@class ExpireableValue

	A wrapper that holds a value with an optional expiration timer.

	The timer counts down when `update()` is called with a delta time.
	Values can be set to never expire using `nonExpiring()`.

	```lua
	local item = ExpireableValue.new("data", 5.0) -- expires in 5 seconds

	item:update(1.0) -- 4 seconds left

	if not item:isExpired() then
		print(item:getValue()) -- "data"
	end
	```
]=]
local ExpireableValue = {}
ExpireableValue.__index = ExpireableValue

export type ExpireableValue<T> = typeof(setmetatable({} :: {
	value: T,
	timeToLive: number
}, ExpireableValue))

function ExpireableValue.new<T>(value: T, timeToLive: number): ExpireableValue<T>
	return setmetatable({
		value = value,
		timeToLive = timeToLive,
	}, ExpireableValue)
end

function ExpireableValue.nonExpiring<T>(value: T): ExpireableValue<T>
	return ExpireableValue.new(value, math.huge)
end

function ExpireableValue.getValue<T>(self: ExpireableValue<T>): T
	return self.value
end

function ExpireableValue.getTimeToLive<T>(self: ExpireableValue<T>): number
	return self.timeToLive
end

function ExpireableValue.canExpire<T>(self: ExpireableValue<T>): boolean
	return self.timeToLive ~= math.huge
end

function ExpireableValue.isExpired<T>(self: ExpireableValue<T>): boolean
	return self.timeToLive <= 0
end

function ExpireableValue.update<T>(self: ExpireableValue<T>, deltaTime: number): ()
	if self:canExpire() then
		self.timeToLive -= deltaTime
	end
end

return ExpireableValue