--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)
local Suggestion = require(ReplicatedStorage.shared.commands.suggestion.Suggestion)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

local MAX_VALUE = math.huge -- 2^31 - 1
local MIN_VALUE = -math.huge -- -2^31

local function tableOnlyHasOneEntry(t: {[any]:any}): boolean
	local i = 0
	for _, _ in t do
		i += 1
		if i > 1 then
			return false
		end
	end

	return true
end

--[=[
	@class Suggestions
]=]
local Suggestions = {}
Suggestions.__index = Suggestions

export type Suggestions = typeof(setmetatable({} :: {
	range: StringRange.StringRange,
	suggestions: {Suggestion.Suggestion}
}, Suggestions))

local EMPTY: Suggestions

function Suggestions.new(range: StringRange.StringRange, suggestions: {Suggestion.Suggestion})
	return setmetatable({
		range = range,
		suggestions = suggestions
	}, Suggestions)
end

function Suggestions.empty(): CompletableFuture.CompletableFuture<Suggestions>
	if (EMPTY :: any) == nil then
		EMPTY = Suggestions.new(StringRange.at(1), {})
	end
	return CompletableFuture.completedFuture(EMPTY)
end

--

function Suggestions.getList(self: Suggestions): {Suggestion.Suggestion}
	return self.suggestions
end

function Suggestions.getRange(self: Suggestions): StringRange.StringRange
	return self.range
end

--

function Suggestions.merge(command: string, input: {Suggestions}): Suggestions
	if next(input) == nil then
		return EMPTY
	elseif tableOnlyHasOneEntry(input) then
		return input[1]
	end

	local texts: {Suggestion.Suggestion} = {}
	for _, suggestions in input do
		for _, text in suggestions:getList() do
			table.insert(texts, text)
		end
	end

	return Suggestions.create(command, texts)
end

function Suggestions.create(command: string, suggestions: {Suggestion.Suggestion}): Suggestions
	if next(suggestions) == nil then
		return EMPTY
	end

	local start = MAX_VALUE
	local end_ = MIN_VALUE
	for _, suggestion in suggestions do
		start = math.min(suggestion:getRange():getStart(), start)
		end_ = math.max(suggestion:getRange():getEnd(), end_)
	end

	local range = StringRange.new(start, end_)
	local texts: {Suggestion.Suggestion} = {}
	for i, suggestion in suggestions do
		texts[i] = suggestion:expand(command, range)
	end

	local sorted = table.clone(suggestions)
	table.sort(sorted, function(a: Suggestion.Suggestion, b: Suggestion.Suggestion)
		return a:compareToIgnoreCase(b)
	end)

	return Suggestions.new(range, sorted)
end

return Suggestions