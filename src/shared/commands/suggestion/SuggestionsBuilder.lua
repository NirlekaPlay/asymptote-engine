--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)
local Suggestion = require(ReplicatedStorage.shared.commands.suggestion.Suggestion)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	@class SuggestionsBuilder
]=]
local SuggestionsBuilder = {}
SuggestionsBuilder.__index = SuggestionsBuilder

export type SuggestionsBuilder = typeof(setmetatable({} :: {
	input: string,
	inputLowerCase: string,
	start: number,
	remaining: string,
	remainingLowerCase: string,
	result: {Suggestion.Suggestion}
}, SuggestionsBuilder))

function SuggestionsBuilder.new(input: string, inputLowerCase: string, start: number): SuggestionsBuilder
	return setmetatable({
		input = input,
		inputLowerCase = inputLowerCase,
		start = start,
		remaining = input:sub(start + 1), -- What the fuck?
		remainingLowerCase = inputLowerCase:sub(start + 1),
		result = {}
	}, SuggestionsBuilder)
end

function SuggestionsBuilder.getInput(self: SuggestionsBuilder): string
	return self.input
end

function SuggestionsBuilder.getStart(self: SuggestionsBuilder): number
	return self.start
end

function SuggestionsBuilder.getRemaining(self: SuggestionsBuilder): string
	return self.remaining
end

function SuggestionsBuilder.getRemainingLowerCase(self: SuggestionsBuilder): string
	return self.remainingLowerCase
end

function SuggestionsBuilder.suggest(self: SuggestionsBuilder, text: string): SuggestionsBuilder
	if text == self.remaining then
		return self
	end
	table.insert(self.result, Suggestion.new(StringRange.between(self.start, #self.input), text))
	return self
end

function SuggestionsBuilder.add(self: SuggestionsBuilder, other: SuggestionsBuilder): SuggestionsBuilder
	local n1 = #self.result
	local n2 = #other.result
	table.move(other.result, 1, n2, n1 + 1, self.result) -- I didnt know this was a thing :o
	return self
end

function SuggestionsBuilder.createOffset(self: SuggestionsBuilder, start: number): SuggestionsBuilder
	return SuggestionsBuilder.new(self.input, self.inputLowerCase, start)
end

function SuggestionsBuilder.build(self: SuggestionsBuilder): Suggestions.Suggestions
	return Suggestions.create(self.input, self.result)
end

function SuggestionsBuilder.buildFuture(self: SuggestionsBuilder): CompletableFuture.CompletableFuture<Suggestions.Suggestions>
	return CompletableFuture.completedFuture(self:build())
end

return SuggestionsBuilder