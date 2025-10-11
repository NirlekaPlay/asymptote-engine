--!strict

--[=[
	@class StringRange
]=]
local StringRange = {}
StringRange.__index = StringRange

export type StringRange = typeof(setmetatable({} :: {
	startPos: number,
	endPos: number
}, StringRange))

function StringRange.new(startPos: number, endPos: number): StringRange
	return setmetatable({
		startPos = startPos,
		endPos = endPos
	}, StringRange)
end

function StringRange.at(pos: number): StringRange
	return StringRange.new(pos, pos)
end

function StringRange.between(startPos: number, endPos: number): StringRange
	return StringRange.new(startPos, endPos)
end

function StringRange.encompassing(a: StringRange, b: StringRange): StringRange
	return StringRange.new(math.min(a:getStart(), b:getStart()), math.max(a:getEnd(), b:getEnd()))
end

function StringRange.isEmpty(self: StringRange): boolean
	return self.startPos == self.endPos
end

--

function StringRange.getStart(self: StringRange): number
	return self.startPos
end

function StringRange.getEnd(self: StringRange): number
	return self.endPos
end

return StringRange