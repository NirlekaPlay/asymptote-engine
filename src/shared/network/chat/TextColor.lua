--!strict

--[=[
	@class TextColor

	Represents a text color that can be serialized
	and consistently converted to other color formats.
]=]
local TextColor = {}
TextColor.__index = TextColor

local DEFAULT_COLOR = 16777215 -- white

export type TextColor = {
	colorValue: number,
	--
	getValue: (self: TextColor) -> number,
	toHex: (self: TextColor) -> string,
	serialize: (self: TextColor) -> string,
	deserialize: (self: TextColor) -> TextColor
}

function TextColor.new(color: number?): TextColor
	return setmetatable({ colorValue = color or DEFAULT_COLOR }, TextColor) :: TextColor
end

function TextColor.fromColor3(color3: Color3): TextColor
	return TextColor.new(TextColor.color3ToInt(color3))
end

function TextColor.getValue(self: TextColor): number
	return self.colorValue
end

function TextColor.toHex(self: TextColor): string
	return TextColor.intToHex(self.colorValue)
end

function TextColor.serialize(self: TextColor): string
	return self:toHex()
end

function TextColor.deserialize(serializedStr: string): TextColor
	return TextColor.new(TextColor.hexToInt(serializedStr))
end

--

function TextColor.hexToInt(hex: string): number
	if hex:sub(1, 1) ~= "#" then
		error(`{hex} is not a valid HTML hexadecimal, must start with '#'.`)
	end

	local attemptNumber = tonumber(hex:sub(2), 16) -- interpert as base 16
	if not attemptNumber then
		error(`Failed to convert {hex} to a number.`)
	end

	return attemptNumber
end

function TextColor.intToHex(int: number): string
	return "#" .. string.format("%06X", int)
end

function TextColor.color3ToInt(color3: Color3): number
	local r = math.floor(color3.R * 255)
	local g = math.floor(color3.G * 255)
	local b = math.floor(color3.B * 255)

	local packed = bit32.bor(
		bit32.lshift(r, 16),
		bit32.lshift(g, 8),
		b
	)

	return packed
end

return TextColor