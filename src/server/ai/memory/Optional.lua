--!nocheck

local Optional = {}
Optional.__index = Optional

local EMPTY: Optional<nil>

export type Optional<T> = typeof(setmetatable({} :: {
	value: T
}, Optional))

function Optional.empty(): Optional<nil>
	if not EMPTY then
		EMPTY = Optional.of(nil)
	end

	return EMPTY
end

function Optional.of<T>(value: T): Optional<T>
	return setmetatable({ value = value }, Optional)
end

function Optional.ofNullable<T>(value: T): Optional<T>
	if not value then
		return EMPTY
	else
		return Optional.of(value) :: Optional<T>
	end
end

function Optional.get<T>(self: Optional<T>): T
	return self.value
end

function Optional.isEmpty<T>(self: Optional<T>): boolean
	return (self.value :: any) == nil
end

function Optional.isPresent<T>(self: Optional<T>): boolean
	return (self.value :: any) ~= nil
end

function Optional.map<T, U>(self: Optional<T>, mapper: (T) -> U): Optional<U>
	if self:isEmpty() then
		return EMPTY
	else
		return Optional.ofNullable(mapper(self:get()))
	end
end

return Optional