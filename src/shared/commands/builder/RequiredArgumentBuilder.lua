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
	argumentType: ArgumentType,
	command: CommandFunction?,
	children: { ArgumentBuilder }
}, RequiredArgumentBuilder))

type ArgumentBuilder = ArgumentBuilder.ArgumentBuilder
type ArgumentType = ArgumentType.ArgumentType
type CommandFunction = CommandFunction.CommandFunction
type CommandNode = CommandNode.CommandNode

function RequiredArgumentBuilder.new(argumentName: string, argumentType: ArgumentType): RequiredArgumentBuilder
	return setmetatable({
		argumentName = argumentName,
		argumentType = argumentType,
		command = nil :: CommandFunction?,
		children = {}
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

function RequiredArgumentBuilder.build(self: RequiredArgumentBuilder): CommandNode
	local node = CommandNode.new(self.argumentName, "argument", self.argumentType)
	node.command = self.command
	
	for _, child in self.children do
		node:addChild(child:build())
	end
	
	return node
end

return RequiredArgumentBuilder