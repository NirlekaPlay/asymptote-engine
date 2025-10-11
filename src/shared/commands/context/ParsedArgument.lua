--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)

local ParsedArgument = {}
ParsedArgument.__index = ParsedArgument

export type ParsedArgument<S, T> = typeof(setmetatable({} :: {
	range: StringRange.StringRange,
	result: T
}, ParsedArgument))

function ParsedArgument.new<S, T>(startPos: number, endPos: number, result: T): ParsedArgument<S, T>
	return setmetatable({
		range = StringRange.between(startPos, endPos),
		result = result
	}, ParsedArgument)
end

function ParsedArgument.getRange<S, T>(self: ParsedArgument<S, T>): StringRange.StringRange
	return self.range
end

function ParsedArgument.getResult<S, T>(self: ParsedArgument<S, T>): T
	return self.result
end

return ParsedArgument