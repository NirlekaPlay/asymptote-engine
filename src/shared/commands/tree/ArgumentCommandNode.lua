--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandContextBuilder = require(ReplicatedStorage.shared.commands.context.CommandContextBuilder)
local ParsedArgument = require(ReplicatedStorage.shared.commands.context.ParsedArgument)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

local USAGE_ARGUMENT_OPEN = "<"
local USAGE_ARGUMENT_CLOSE = ">"

--[=[
	@class ArgumentCommandNode

	An `ArgumentCommandNode` represents a command node that matches an argument. It is used to define commands that have variable input.
	Example, in a command like `/give <player> <item>`, the *`<player>`* and *`<item>`* parts would be represented by `ArgumentCommandNode`s.
	Because arguments can be used to turn a raw input text from the user into a usable value that's passed to the command's execution function.
]=]
local ArgumentCommandNode = setmetatable({}, { __index = CommandNode })
ArgumentCommandNode.__index = ArgumentCommandNode

export type ArgumentCommandNode<S> = CommandNode.CommandNode<S> & {
	name: string,
	argumentType: ArgumentType<S>,
	customSuggestions: SuggestionsBuilder,
}
type ArgumentType<S> = ArgumentType.ArgumentType<S>
type CommandContext<S> = CommandContext.CommandContext<S>
type CommandContextBuilder<S> = CommandContextBuilder.CommandContextBuilder<S>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type Predicate<S> = (context: S) -> boolean
type StringReader = StringReader.StringReader
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

function ArgumentCommandNode.new<S>(name: string, argumentType: ArgumentType<S>, command: CommandFunction<S>, requirement: Predicate<S>, redirect: CommandNode<S>, customSuggestions: SuggestionsBuilder?): ArgumentCommandNode<S>
	local self = setmetatable((CommandNode).new("", "argument", nil, requirement, redirect, nil), ArgumentCommandNode) :: any
	self.name = name
	self.argumentType = argumentType
	self.customSuggestions = customSuggestions
	--
	self.command = command
	return self
end

function ArgumentCommandNode.getName<S>(self: ArgumentCommandNode<S>): string
	return self.name
end

function ArgumentCommandNode.getUsageText<S>(self: ArgumentCommandNode<S>): string
	return USAGE_ARGUMENT_OPEN .. self.name .. USAGE_ARGUMENT_CLOSE
end

function ArgumentCommandNode.parse<S>(self: ArgumentCommandNode<S>, reader: StringReader, contextBuilder: CommandContextBuilder<S>): ()
	local startPos = reader:getCursorPos()
	local remaining = reader:getRemaining()

	-- TODO: Brigadier just pass the `StringReader` object to the argument and let it do the parsing itself,
	-- currently `self.argumentType:parse(remaining)` accepts the remaining string and returns the result and the number of characters consumed
	local result, consumed = self.argumentType:parse(remaining)
	reader:setCursorPos(startPos + consumed)
	local parsed = ParsedArgument.new(startPos, reader:getCursorPos(), result)
	contextBuilder:withArgument(self.name, parsed)
	contextBuilder:withNode(self, parsed:getRange())
end

function ArgumentCommandNode.listSuggestions<S>(self: ArgumentCommandNode<S>, context: CommandContext<S>, suggestionsBuilder: SuggestionsBuilder): CompletableFuture<Suggestions>
	if self.customSuggestions == nil then
		return self.argumentType:listSuggestions(context, suggestionsBuilder)
	else
		return self.customSuggestions:getSuggestions(context, suggestionsBuilder)
	end
end

function ArgumentCommandNode.createBuilder<S, T>(self: ArgumentCommandNode<S>): ArgumentBuilder.ArgumentBuilder<S, T>
	local builder = RequiredArgumentBuilder.argument(self.literal, self.argumentType)
	if self.requirement then
		builder:requires(self.requirement)
	end
	if self.redirect then
		builder:redirect(self.redirect)
	end
	if self.customSuggestions then
		builder:suggests(self.customSuggestions)
	end
	if self:getCommand() ~= nil then
		builder:executes(self:getCommand())
	end
	return builder
end

--

function ArgumentCommandNode.getNodeType<S>(self: ArgumentCommandNode<S>): number
	return CommandNodeType.ARGUMENT
end

function ArgumentCommandNode.__tostring<S>(self: ArgumentCommandNode<S>): string
	return `<argument {self.name}: {self.argumentType}>`
end

return ArgumentCommandNode