--!nocheck

local Optional = {}
Optional.__index = Optional

local EMPTY: Optional<nil>

export type Optional<T> = typeof(setmetatable({} :: {
	value: T,
	filter: (self: Optional<T>, predicate: (T) -> boolean) -> Optional<T>,
	ifPresent: (self: Optional<T>, callback: (T) -> ()) -> (),
	map: (self: Optional<T>, mapper: (T) -> any) -> Optional<any>
}, Optional))

function Optional.empty(): Optional<nil>
	if not EMPTY then
		local newEmpty = setmetatable({ value = nil }, Optional)
		EMPTY = newEmpty
	end

	return EMPTY
end

function Optional.of<T>(value: T): Optional<T>
	assert(value ~= nil, "Optional.of() received a nil value. Use Optional.ofNullable(nil) if a nil value is expected.")
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

function Optional.ifPresent<T>(self: Optional<T>, callback: (T) -> ()): ()
	if self.value ~= nil then
		callback(self.value)
	end
end

function Optional.filter<T>(self: Optional<T>, predicate: (T) -> boolean): Optional<T>
	if self:isEmpty() then
		return self
	else
		return if predicate(self.value) then self else EMPTY
	end
end

function Optional.map<T, U>(self: Optional<T>, mapper: (T) -> U): Optional<U>
	if self:isEmpty() then
		return EMPTY
	else
		return Optional.ofNullable(mapper(self.value))
	end
end

return Optional