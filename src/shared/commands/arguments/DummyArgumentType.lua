--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	@class DummyArgumentType

	This module serves as your blank canvas for making a new
	argument type.
	Make sure to correctly type the `any` types and replace the
	`DummyArgumentType` name in the entire file to your
	argument type name.
]=]
local DummyArgumentType = {}
DummyArgumentType.__index = DummyArgumentType

export type DummyArgumentType = ArgumentType<any> & {}

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandContext<S> = CommandContext.CommandContext<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

function DummyArgumentType.dummy(): DummyArgumentType
	return {} :: any
end

function DummyArgumentType.getDummy<S>(context: CommandContext<S>, name: string): any
	return {}
end

function DummyArgumentType.listSuggestions<S>(self: DummyArgumentType, context: CommandContext<S>, builder: SuggestionsBuilder): CompletableFuture<Suggestions>
	return builder:buildFuture()
end

function DummyArgumentType.parse(self: DummyArgumentType, input: string): (any, number)
	return {}
end

return DummyArgumentType