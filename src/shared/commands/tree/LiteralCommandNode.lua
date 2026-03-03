--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContextBuilder = require(ReplicatedStorage.shared.commands.context.CommandContextBuilder)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)
local UString = require(ReplicatedStorage.shared.util.string.UString)

--[=[
	@class LiteralCommandNode

	A `LiteralCommandNode` represents a command node that matches a specific literal string.
	It is used to define commands that have fixed keywords or phrases.
	Example, in a command like `/give <player> <item>`, the *`give`* part would be represented by a `LiteralCommandNode`.
]=]
local LiteralCommandNode = setmetatable({}, { __index = CommandNode })
LiteralCommandNode.__index = LiteralCommandNode

export type LiteralCommandNode<S> = CommandNode.CommandNode<S> & {
	literal: string,
	literalLowerCase: string
}
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CommandContextBuilder<S> = CommandContextBuilder.CommandContextBuilder<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type Predicate<S> = (context: S) -> boolean
type StringReader = StringReader.StringReader
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

function LiteralCommandNode.new<S>(literal: string, command: CommandFunction<S>?, requirement: Predicate<S>, redirect: CommandNode<S>): LiteralCommandNode<S>
	local self = setmetatable((CommandNode :: any).new("", "literal", nil, nil, nil, nil), LiteralCommandNode) :: any
	self.literal = literal
	self.literalLowerCase = literal:lower()
	return self
end

function LiteralCommandNode.getName<S>(self: LiteralCommandNode<S>): string
	return self.literal
end

function LiteralCommandNode.getUsageText<S>(self: LiteralCommandNode<S>): string
	return self.literal
end

function LiteralCommandNode.parse<S>(self: LiteralCommandNode<S>, reader: StringReader, contextBuilder: CommandContextBuilder<S>): ()
	local startPos = reader:getCursorPos()
	local endPos = self:_parse(reader)
	if endPos > -1 then
		contextBuilder:withNode(self, startPos, endPos)
	else
		error("Invalid command literal: " .. self.literal)
	end
end

function LiteralCommandNode._parse<S>(self: LiteralCommandNode<S>, reader: StringReader): number
	local start = reader:getCursorPos()
	if reader:canRead(#self.literal) then
		local endPos = start + #self.literal
		if reader:getString():sub(start + 1, endPos) == self.literal then
			reader:setCursorPos(endPos)
			if not reader:canRead() or reader:peek() == ' ' then
				return endPos
			else
				reader:setCursorPos(start)
			end
		end
	end
	return -1
end

function LiteralCommandNode.listSuggestions<S>(self: LiteralCommandNode<S>, context: CommandContextBuilder<S>, suggestionsBuilder: SuggestionsBuilder): CompletableFuture<Suggestions>
	if UString.startsWith(self.literalLowerCase, suggestionsBuilder:getRemainingLowerCase()) then
		return suggestionsBuilder:suggest(self.literal):buildFuture()
	else
		return Suggestions.empty()
	end
end

function LiteralCommandNode.createBuilder<S, T>(self: LiteralCommandNode<S>): ArgumentBuilder.ArgumentBuilder<S, T>
	local builder = LiteralArgumentBuilder.literal(self.literal) :: LiteralArgumentBuilder.LiteralArgumentBuilder<S>
	if self.requirement then
		builder:requires(self.requirement)
	end
	if self.redirect then
		builder:redirect(self.redirect)
	end
	return builder
end

--

function LiteralCommandNode.getNodeType<S>(self: LiteralCommandNode<S>): number
	return CommandNodeType.LITERAL
end

function LiteralCommandNode.__tostring<S>(self: LiteralCommandNode<S>): string
	return `<literal {self.literal}>`
end

return LiteralCommandNode