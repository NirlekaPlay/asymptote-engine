--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local SuggestionProvider = require(ReplicatedStorage.shared.commands.suggestion.SuggestionProvider)
local ArgumentCommandNode = require(ReplicatedStorage.shared.commands.tree.ArgumentCommandNode)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

--[=[
	@class RequiredArgumentBuilder
]=]
local RequiredArgumentBuilder = {}
RequiredArgumentBuilder.__index = RequiredArgumentBuilder

export type RequiredArgumentBuilder<S> = {
	argumentName: string,
	argumentType: ArgumentType<any>,
	command: CommandFunction<S>?,
	children: { ArgumentBuilder<S> },
	redirectNode: CommandNode<S>?,
	requirement: Predicate<S>?,
	suggestionsProvider: SuggestionProvider<S>,
	description: string?,
	--
	getCommand: <S>(self: RequiredArgumentBuilder<S>) -> CommandFunction<S>?,
	getRedirect: <S>(self: RequiredArgumentBuilder<S>) -> CommandNode<S>?,
	executes: (self: RequiredArgumentBuilder<S>, command: CommandFunction<S>) -> RequiredArgumentBuilder<S>,
	andThen: (self: RequiredArgumentBuilder<S>, child: ArgumentBuilder<S>) -> RequiredArgumentBuilder<S>,
	redirect: (self: RequiredArgumentBuilder<S>, target: CommandNode<S>) -> RequiredArgumentBuilder<S>,
	build: (self: RequiredArgumentBuilder<S>) -> CommandNode<S>,
	suggests: <S>(self: RequiredArgumentBuilder<S>, provider: SuggestionProvider<S>) -> RequiredArgumentBuilder<S>,
	requires: <S>(self: RequiredArgumentBuilder<S>, requirement: Predicate<S>) -> RequiredArgumentBuilder<S>,
	describe: <S>(self: RequiredArgumentBuilder<S>, description: string) -> RequiredArgumentBuilder<S>
}

type ArgumentBuilder<S> = ArgumentBuilder.ArgumentBuilder<S, any>
type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type Predicate<T> = (T) -> boolean
type SuggestionProvider<S> = SuggestionProvider.SuggestionProvider<S>

function RequiredArgumentBuilder.new<S, T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder<S>
	return setmetatable({
		argumentName = argumentName,
		argumentType = argumentType,
		command = nil :: CommandFunction<S>?,
		children = {},
		redirectNode = nil :: CommandNode<S>?
	}, RequiredArgumentBuilder) :: RequiredArgumentBuilder<S>
end

function RequiredArgumentBuilder.argument<S, T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder<S>
	return RequiredArgumentBuilder.new(argumentName, argumentType)
end

function RequiredArgumentBuilder.executes<S>(self: RequiredArgumentBuilder<S>, commandFunc: CommandFunction<S>): RequiredArgumentBuilder<S>
	self.command = commandFunc
	return self
end

function RequiredArgumentBuilder.describe<S>(self: RequiredArgumentBuilder<S>, description: string): RequiredArgumentBuilder<S>
	self.description = description
	return self
end

function RequiredArgumentBuilder.suggests<S>(self: RequiredArgumentBuilder<S>, provider: SuggestionProvider<S>): RequiredArgumentBuilder<S>
	self.suggestionsProvider = provider
	return self
end

function RequiredArgumentBuilder.requires<S>(self: RequiredArgumentBuilder<S>, predicate: Predicate<S>): RequiredArgumentBuilder<S>
	self.requirement = predicate
	return self
end

function RequiredArgumentBuilder.andThen<S>(self: RequiredArgumentBuilder<S>, child: ArgumentBuilder<S>): RequiredArgumentBuilder<S>
	table.insert(self.children, child)
	return self
end

function RequiredArgumentBuilder.build<S>(self: RequiredArgumentBuilder<S>): CommandNode<S>
	local node = ArgumentCommandNode.new(self.argumentName, self.argumentType, self.command, self.requirement, self.redirectNode, self.suggestionsProvider, self.description)

	if not node.redirect then
		for _, child in self.children do
			node:addChild(child:build())
		end
	end
	
	return node
end

return RequiredArgumentBuilder