--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)
local StringBuilder = require(ReplicatedStorage.shared.commands.util.StringBuilder)

--[=[
	@class Suggestion
]=]
local Suggestion = {}
Suggestion.__index = Suggestion

export type Suggestion = typeof(setmetatable({} :: {
	range: StringRange.StringRange,
	text: string
}, Suggestion))

function Suggestion.new(
	range: StringRange.StringRange,
	text: string
): Suggestion
	return setmetatable({
		range = range,
		text = text
	}, Suggestion)
end

function Suggestion.getRange(self: Suggestion): StringRange.StringRange
	return self.range
end

function Suggestion.getText(self: Suggestion): string
	return self.text
end

function Suggestion.compareToIgnoreCase(self: Suggestion, b: Suggestion): boolean
	return self.text:lower() < b.text:lower()
end

--

function Suggestion.expand(self: Suggestion, command: string, range: StringRange.StringRange): Suggestion
	if range:equals(self.range) then
		return self
	end

	local result = StringBuilder.new()
	if range:getStart() < self.range:getStart() then
		result:append(command:sub(range:getStart(), self.range:getStart()))
	end

	result:append(self.text)

	if (range:getEnd() > self.range:getEnd()) then
		result:append(command:sub(self.range:getEnd(), range:getEnd()))
	end

	return Suggestion.new(range, result:toString())
end

return Suggestion