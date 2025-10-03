--!strict

--[=[
	@class IntegerArgumentType

	An integer number argument type. Integers are whole numbers.
	An optional minimum and maximum parameters can be set.
	The default minimum and maximum parameters are **-2^23** and **2^23**.
]=]
local IntegerArgumentType = {}
IntegerArgumentType.__index = IntegerArgumentType

local DEFAULT_MIN_INT = -2^23
local DEFAULT_MAX_INT = 2^23

export type IntegerArgumentType = {
	minimum: number,
	maximum: number,
	parse: (self: IntegerArgumentType, input: string) -> (number, number)
}

function IntegerArgumentType.new(min: number, max: number): IntegerArgumentType
	return setmetatable({
		minimum = min,
		maximum = max
	}, IntegerArgumentType) :: IntegerArgumentType
end

--[=[
	An integer argument type.
	If both `min` and `max` are not given, it will default to **-2^23** and **-2^23** respectively.
	If `min` is given, it will use the defined `min` with the default `max`.
	If both `min` and `max` are given, it will use both of them respectively.
	
	The parser will throw an error if no integer is provided, or the value is outside the
	`min` and `max` range.
]=]
function IntegerArgumentType.integer(min: number?, max: number?): IntegerArgumentType
	if min then
		return IntegerArgumentType.new(min, DEFAULT_MAX_INT)
	elseif min and max then
		return IntegerArgumentType.new(min, max)
	else
		return IntegerArgumentType.new(DEFAULT_MIN_INT, DEFAULT_MAX_INT)
	end
end

function IntegerArgumentType.parse(self: IntegerArgumentType, input: string): (number, number)
	local str = input:match("^%-?%d+$")
	local num = tonumber(str)
	if not num then
		error(`Expected integer, got: {num}`)
	elseif num < self.minimum then
		error(`Integer too low, below defined {self.minimum} minimum limit, got {num}`)
	elseif num > self.maximum then
		error(`Integer too big, above defined {self.minimum} maximum limit, got {num}`)
	end

	local len = tostring(str):len()

	if input:sub(1, 1) == "-" then
		len += 1
	end

	return num, len
end

return IntegerArgumentType