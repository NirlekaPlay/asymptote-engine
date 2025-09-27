--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)

--[=[
	@class CommandNode
]=]
local CommandNode = {}
CommandNode.__index = CommandNode

export type CommandNode = typeof(setmetatable({} :: {
	name: string,
	nodeType: "literal" | "argument",
	argumentType: ArgumentType?,
	command: CommandFunction?,
	children: { [string]: CommandNode }
}, CommandNode))

type ArgumentType = ArgumentType.ArgumentType
type CommandFunction = CommandFunction.CommandFunction

function CommandNode.new(name: string, nodeType: "literal" | "argument", argumentType: ArgumentType?): CommandNode
	return setmetatable({
		name = name,
		nodeType = nodeType,
		argumentType = argumentType,
		command = nil :: CommandFunction?,
		children = {}
	}, CommandNode)
end

function CommandNode.addChild(self: CommandNode, child: CommandNode)
	self.children[child.name] = child
end

function CommandNode.getChild(self: CommandNode, name: string): CommandNode?
	return self.children[name]
end

function CommandNode.canExecute(self: CommandNode): boolean
	return self.command ~= nil
end

return CommandNode