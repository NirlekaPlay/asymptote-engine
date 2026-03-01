--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	An argument parser that returns a value of type `T` and the amount of
	characters it has consumed after parsing.
]=]
export type ArgumentType<T> = {
	parse: (self: ArgumentType<T>, input: string) -> (T, number), -- returns (value, charactersConsumed)
	listSuggestions: (<S>(self: ArgumentType<T>, context: CommandContext.CommandContext<S>, builder: SuggestionsBuilder.SuggestionsBuilder) -> CompletableFuture.CompletableFuture<Suggestions.Suggestions>)?
}

return nil