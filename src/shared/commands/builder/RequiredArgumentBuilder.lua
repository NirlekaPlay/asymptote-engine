--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
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
	--
	executes: (self: RequiredArgumentBuilder<S>, command: CommandFunction<S>) -> RequiredArgumentBuilder<S>,
	andThen: (self: RequiredArgumentBuilder<S>, child: ArgumentBuilder<S>) -> RequiredArgumentBuilder<S>,
	redirect: (self: RequiredArgumentBuilder<S>, target: CommandNode<S>) -> RequiredArgumentBuilder<S>,
	build: (self: RequiredArgumentBuilder<S>) -> CommandNode<S>
}

type ArgumentBuilder<S> = ArgumentBuilder.ArgumentBuilder<S>
type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>

function RequiredArgumentBuilder.new<S, T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder<S>
	return setmetatable({
		argumentName = argumentName,
		argumentType = argumentType,
		command = nil :: CommandFunction<S>?,
		children = {},
		redirectNode = nil :: CommandNode<S>?
	}, RequiredArgumentBuilder) :: RequiredArgumentBuilder<S>
end

function RequiredArgumentBuilder.executes<S>(self: RequiredArgumentBuilder<S>, commandFunc: CommandFunction<S>): RequiredArgumentBuilder<S>
	self.command = commandFunc
	return self
end

function RequiredArgumentBuilder.andThen<S>(self: RequiredArgumentBuilder<S>, child: ArgumentBuilder<S>): RequiredArgumentBuilder<S>
	table.insert(self.children, child)
	return self
end

function RequiredArgumentBuilder.build<S>(self: RequiredArgumentBuilder<S>): CommandNode<S>
	local node = CommandNode.new(self.argumentName, "argument", self.argumentType)
	node.command = self.command
	node.redirect = self.redirectNode

	if not node.redirect then
		for _, child in self.children do
			node:addChild((child :: any):build())
		end
	end
	
	return node
end

return RequiredArgumentBuilder