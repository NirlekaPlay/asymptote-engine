--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

export type SuggestionProvider<S> = {
	getSuggestions: (self: SuggestionProvider<S>, context: CommandContext.CommandContext<S>, builder: SuggestionsBuilder.SuggestionsBuilder) -> CompletableFuture.CompletableFuture<Suggestions.Suggestions>
}

return nil