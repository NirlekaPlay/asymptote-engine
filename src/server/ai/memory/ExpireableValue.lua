--!strict

local ExpireableValue = {}
ExpireableValue.__index = ExpireableValue

export type ExpireableValue<T> = typeof(setmetatable({} :: {
	value: T?,
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

function ExpireableValue.getValue<T>(self: ExpireableValue<T>): T?
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

function ExpireableValue.update<T>(self: ExpireableValue<T>, delta: number): ()
	if self:canExpire() then
		self.timeToLive -= delta
	end
end

return ExpireableValue