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

export type RequiredArgumentBuilder = typeof(setmetatable({} :: {
	argumentName: string,
	argumentType: ArgumentType<any>,
	command: CommandFunction?,
	children: { ArgumentBuilder },
	redirectNode: CommandNode<S>?
}, RequiredArgumentBuilder))

type ArgumentBuilder = ArgumentBuilder.ArgumentBuilder
type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction = CommandFunction.CommandFunction
type CommandNode<S> = CommandNode.CommandNode<S>

function RequiredArgumentBuilder.new<T>(argumentName: string, argumentType: ArgumentType<T>): RequiredArgumentBuilder
	return setmetatable({
		argumentName = argumentName,
		argumentType = argumentType,
		command = nil :: CommandFunction?,
		children = {},
		redirectNode = nil :: CommandNode<S>?
	}, RequiredArgumentBuilder)
end

function RequiredArgumentBuilder.executes(self: RequiredArgumentBuilder, commandFunc: CommandFunction): ArgumentBuilder
	self.command = commandFunc
	return self :: ArgumentBuilder
end

function RequiredArgumentBuilder.andThen(self: RequiredArgumentBuilder, child: ArgumentBuilder): ArgumentBuilder
	table.insert(self.children, child)
	return self :: ArgumentBuilder
end

function RequiredArgumentBuilder.build(self: RequiredArgumentBuilder): CommandNode<S>
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