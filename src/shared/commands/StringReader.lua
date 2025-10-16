--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ImmutableStringReader = require(ReplicatedStorage.shared.commands.ImmutableStringReader)
local UString = require(ReplicatedStorage.shared.suggestion.UString)

--[=[
	@class StringReader

	Provides a Unicode-aware way to read strings.
]=]
local StringReader = {}
StringReader.__index = StringReader

export type StringReader = ImmutableStringReader.ImmutableStringReader & {
	string: string,
	characters: { string },
	length: number,
	cursorPos: number
} & typeof(StringReader)

function StringReader.new(str: string, chars: { string }, cursorPos: number): StringReader
	return setmetatable({
		string = str,
		characters = chars,
		length = #chars,
		cursorPos = cursorPos
	}, StringReader) :: StringReader
end

function StringReader.fromOther(other: StringReader): StringReader
	local copy = StringReader.fromString(other.string)
	copy.cursorPos = other.cursorPos
	return copy
end

function StringReader.fromString(str: string): StringReader
	return StringReader.new(str, UString.explodeString(str), 0)
end

--

function StringReader.getString(self: StringReader): string
	return self.string
end

function StringReader.setCursorPos(self: StringReader, pos: number): ()
	self.cursorPos = pos
end

function StringReader.getRemainingLength(self: StringReader): number
	return self.length - self.cursorPos
end

function StringReader.getTotalLength(self: StringReader): number
	return self.length
end

function StringReader.getCursorPos(self: StringReader): number
	return self.cursorPos
end

function StringReader.getRead(self: StringReader): string
	return table.concat(self:getEncompassingChars(0, self.cursorPos))
end

function StringReader.getRemaining(self: StringReader): string
	return table.concat(self:getEncompassingChars(self.cursorPos, self.length))
end

function StringReader.canReadLength(self: StringReader, length: number): boolean
	return self.cursorPos + length <= self.length
end

function StringReader.canRead(self: StringReader): boolean
	return self:canReadLength(1)
end

function StringReader.peek(self: StringReader): string
	return self.characters[self.cursorPos + 1]
end

function StringReader.peekOffset(self: StringReader, offset: number): string
	return self.characters[self.cursorPos + offset + 1]
end

function StringReader.read(self: StringReader): string
	local char = self.characters[self.cursorPos + 1]
	self.cursorPos += 1
	return char
end

function StringReader.skip(self: StringReader): ()
	self.cursorPos += 1
end

function StringReader.skipWhitespace(self: StringReader): ()
	while self:canRead() and UString.isWhitespace(self:peek()) do
		self:skip()
	end
end

--

function StringReader.getEncompassingChars(self: StringReader, startPos: number, endPos: number): {string}
	local chars = table.create(endPos - startPos) :: {string}
	for i = startPos, endPos - 1 do
		table.insert(chars, self.characters[i + 1])  -- +1 to convert 0-based pos to 1-based index
	end
	return chars
end

return StringReader