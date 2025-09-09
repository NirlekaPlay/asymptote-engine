--!nocheck

--[=[
	@class Optional

	A port of Java's Optional utility class.
]=]
local Optional = {}
Optional.__index = Optional

local EMPTY: Optional<nil>

export type Optional<T> = typeof(setmetatable({} :: {
	value: T,
	filter: (self: Optional<T>, predicate: (T) -> boolean) -> Optional<T>,
	ifPresent: (self: Optional<T>, callback: (T) -> ()) -> (),
	map: (self: Optional<T>, mapper: (T) -> any) -> Optional<any>,
	flatMap: (self: Optional<T>, mapper: (T)) -> Optional<any>
}, Optional))

--[=[
	Returns an empty `Optional` instance. No value is present for this `Optional`.
]=]
function Optional.empty(): Optional<nil>
	if not EMPTY then
		local newEmpty = setmetatable({ value = nil }, Optional)
		EMPTY = newEmpty
	end

	return EMPTY
end

--[=[
	Returns an `Optional` describing the given non-`nil` value.
	<br/>
	Throws an error if the given a value that is `nil`. 
]=]
function Optional.of<T>(value: T): Optional<T>
	assert(value ~= nil, "Optional.of() received a nil value. Use Optional.ofNullable(nil) if a nil value is expected.")
	return setmetatable({ value = value }, Optional)
end

--[=[
	Returns an `Optional` describing the given value, if non-`nil`, otherwise returns an empty `Optional`.
]=]
function Optional.ofNullable<T>(value: T): Optional<T>
	if value == nil then
		return EMPTY
	else
		return Optional.of(value) :: Optional<T>
	end
end

--[=[
	If a value is present, returns the value, otherwise throws an error.
]=]
function Optional.get<T>(self: Optional<T>): T
	if self.value == nil then
		error("Optional.get() called on empty Optional. Check with hasValue() first.")
	end

	return self.value
end

--[=[
	If a value is not present, returns `true`, otherwise `false`.
]=]
function Optional.isEmpty<T>(self: Optional<T>): boolean
	return (self.value :: any) == nil
end

--[=[
	If a value is present, returns `true`, otherwise `false`.
]=]
function Optional.isPresent<T>(self: Optional<T>): boolean
	return (self.value :: any) ~= nil
end

--[=[
	If a value is present, calls the given function with the value, otherwise does nothing.
]=]
function Optional.ifPresent<T>(self: Optional<T>, callback: (T) -> ()): ()
	if self.value ~= nil then
		callback(self.value)
	end
end

--[=[
	If a value is present, and the predicate function with the given value returns `true`,
	returns an `Optional` describing the value, otherwise returns an empty `Optional`.
]=]
function Optional.filter<T>(self: Optional<T>, predicate: (T) -> boolean): Optional<T>
	if self:isEmpty() then
		return self
	else
		return if predicate(self.value) then self else EMPTY
	end
end

--[=[
	If a value is present, returns an <code>Optional</code> describing (as if by ofNullable) the result of applying<br/>
	the given mapping function to the value, otherwise returns an empty <code>Optional</code>.<br/>
	<p>If the mapping function returns <code>nil</code> then this method returns an empty <code>Optional</code>.
]=]
function Optional.map<T, U>(self: Optional<T>, mapper: (T) -> U): Optional<U>
	if self:isEmpty() then
		return EMPTY
	else
		return Optional.ofNullable(mapper(self.value))
	end
end

--[=[
	If a value is present, returns the result of applying the given `Optional`-bearing mapping function to the value,
	otherwise returns an empty `Optional`.<br/>

	This method is similar to <code>map(Function)</code>, but the mapping function is one whose result is already an `Optional`,
	and if invoked, `flatMap` does not wrap it within an additional `Optional`.

	Throws an error if the mappin function returns `nil`.
]=]
function Optional.flatMap<T, U>(self: Optional<T>, mapper: (T) -> Optional<U>): U
	if self:isEmpty() then
		return EMPTY
	else
		local result = mapper(self.value)
		assert(result ~= nil, "Optional<T>::flatMap(): mapper returns nil")
		return result
	end
end

--[=[
	If a value is present, returns the value, otherwise returns `other`, which may be `nil`.
]=]
function Optional.orElse<T, U>(self: Optional<T>, other: U): T | U
	return if (self.value :: any) ~= nil then self.value else other
end

--[=[
	If a value is present, returns the value, otherwise returns the result
	returned by the `callback` function.
]=]
function Optional.orElseGet<T, U>(self: Optional<T>, callback: () -> U): T | U
	return if (self.value :: any) ~= nil then self.value else callback()
end

return Optional