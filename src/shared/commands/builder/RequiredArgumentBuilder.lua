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

export type RequiredArgumentBuilder<S, T> = {
	argumentName: string,
	argumentType: ArgumentType<T>,
	command: CommandFunction<S>?,
	children: { ArgumentBuilder<S> },
	redirectNode: CommandNode<S>?,
	requirement: Predicate<S>?,
	suggestionsProvider: SuggestionProvider<S>,
	description: string?,
	--
	getCommand: <S>(self: RequiredArgumentBuilder<S, T>) -> CommandFunction<S>?,
	getRedirect: <S>(self: RequiredArgumentBuilder<S, T>) -> CommandNode<S>?,
	executes: (self: RequiredArgumentBuilder<S, T>, command: CommandFunction<S>) -> RequiredArgumentBuilder<S, T>,
	andThen: (self: RequiredArgumentBuilder<S, T>, child: ArgumentBuilder<S>) -> RequiredArgumentBuilder<S, T>,
	redirect: (self: RequiredArgumentBuilder<S, T>, target: CommandNode<S>) -> RequiredArgumentBuilder<S, T>,
	build: (self: RequiredArgumentBuilder<S, T>) -> CommandNode<S>,
	suggests: <S>(self: RequiredArgumentBuilder<S, T>, provider: SuggestionProvider<S>) -> RequiredArgumentBuilder<S, T>,
	requires: <S>(self: RequiredArgumentBuilder<S, T>, requirement: Predicate<S>) -> RequiredArgumentBuilder<S, T>,
	describe: <S>(self: RequiredArgumentBuilder<S, T>, description: string) -> RequiredArgumentBuilder<S, T>
}

type ArgumentBuilder<S> = ArgumentBuilder.ArgumentBuilder<S, any>
type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type Predicate<T> = (T) -> boolean
type SuggestionProvider<S> = SuggestionProvider.SuggestionProvider<S>

function RequiredArgumentBuilder.new<S, T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder<S, T>
	return setmetatable({
		argumentName = argumentName,
		argumentType = argumentType,
		command = nil :: CommandFunction<S>?,
		children = {},
		redirectNode = nil :: CommandNode<S>?
	}, RequiredArgumentBuilder) :: RequiredArgumentBuilder<S, T>
end

function RequiredArgumentBuilder.argument<S, T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder<S, T>
	return RequiredArgumentBuilder.new(argumentName, argumentType)
end

function RequiredArgumentBuilder.executes<S, T>(self: RequiredArgumentBuilder<S, T>, commandFunc: CommandFunction<S>): RequiredArgumentBuilder<S, T>
	self.command = commandFunc
	return self
end

function RequiredArgumentBuilder.describe<S, T>(self: RequiredArgumentBuilder<S, T>, description: string): RequiredArgumentBuilder<S, T>
	self.description = description
	return self
end

function RequiredArgumentBuilder.suggests<S, T>(self: RequiredArgumentBuilder<S, T>, provider: SuggestionProvider<S>): RequiredArgumentBuilder<S, T>
	self.suggestionsProvider = provider
	return self
end

function RequiredArgumentBuilder.requires<S, T>(self: RequiredArgumentBuilder<S, T>, predicate: Predicate<S>): RequiredArgumentBuilder<S, T>
	self.requirement = predicate
	return self
end

function RequiredArgumentBuilder.andThen<S, T>(self: RequiredArgumentBuilder<S, T>, child: ArgumentBuilder<S>): RequiredArgumentBuilder<S, T>
	table.insert(self.children, child)
	return self
end

function RequiredArgumentBuilder.build<S, T>(self: RequiredArgumentBuilder<S, T>): CommandNode<S>
	local node = ArgumentCommandNode.new(self.argumentName, self.argumentType, self.command, self.requirement, self.redirectNode, self.suggestionsProvider, self.description)

	if not node.redirect then
		for _, child in self.children do
			node:addChild(child:build())
		end
	end
	
	return node
end

return RequiredArgumentBuilder