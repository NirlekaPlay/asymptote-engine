--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandContextBuilder = require(ReplicatedStorage.shared.commands.context.CommandContextBuilder)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	@class RootCommandNode

	A `RootCommandNode` is the root of a command tree. It is the entry point for all commands.
]=]
local RootCommandNode = setmetatable({}, { __index = CommandNode })
RootCommandNode.__index = RootCommandNode

export type RootCommandNode<S> = CommandNode.CommandNode<S> & {}
type CommandContext<S> = CommandContext.CommandContext<S>
type CommandContextBuilder<S> = CommandContextBuilder.CommandContextBuilder<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type StringReader = StringReader.StringReader
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

function RootCommandNode.new<S>(): RootCommandNode<S>
	local self = setmetatable((CommandNode :: any).new("", "root", nil, nil, nil, nil), RootCommandNode) :: any
	return self
end

function RootCommandNode.getName<S>(self: RootCommandNode<S>): string
	return ""
end

function RootCommandNode.getUsageText<S>(self: RootCommandNode<S>): string
	return ""
end

function RootCommandNode.parse<S>(self: RootCommandNode<S>, reader: StringReader, contextBuilder: CommandContextBuilder<S>): ()
	return
end

function RootCommandNode.listSuggestions<S>(self: RootCommandNode<S>, context: CommandContext<S>, suggestionsBuilder: SuggestionsBuilder): CompletableFuture<Suggestions>
	return Suggestions.empty()
end

function RootCommandNode.createBuilder<S>(self: RootCommandNode<S>): ArgumentBuilder.ArgumentBuilder<S, any>
	error("Cannot convert root into a builder")
end

--

function RootCommandNode.getNodeType<S>(self: RootCommandNode<S>): number
	return CommandNodeType.ROOT
end

function RootCommandNode.__tostring<S>(self: RootCommandNode<S>): string
	return "<root>"
end

return RootCommandNode