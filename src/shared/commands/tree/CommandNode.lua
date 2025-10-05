--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)

--[=[
	@class CommandNode
]=]
local CommandNode = {}
CommandNode.__index = CommandNode

export type CommandNode<S> = typeof(setmetatable({} :: {
	name: string,
	nodeType: "literal" | "argument",
	requirement: Predicate<S>?,
	redirect: CommandNode<S>?,
	argumentType: ArgumentType<any>?,
	command: CommandFunction<S>?,
	children: { [string]: CommandNode<S> }
}, CommandNode))

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type Predicate<T> = (T) -> boolean

function CommandNode.new<S>(name: string, nodeType: "literal" | "argument", argumentType: ArgumentType<any>?, requirement: Predicate<S>?, redirect: CommandNode<S>?): CommandNode<S>
	return setmetatable({
		name = name,
		nodeType = nodeType,
		requirement = requirement,
		redirect = redirect,
		argumentType = argumentType,
		command = nil :: CommandFunction<S>?,
		children = {}
	}, CommandNode)
end

function CommandNode.getName<S>(self: CommandNode<S>): string
	return self.name
end

function CommandNode.canUse<S>(self: CommandNode<S>, source: S): boolean
	if not self.requirement then
		return true
	else
		return self.requirement(source)
	end
end

function CommandNode.getUsageText<S>(self: CommandNode<S>): string
	-- This is utterly fucking retarded.
	if self.nodeType == "literal" then
		return self.name
	elseif self.nodeType == "argument" then
		return "<" .. self.name .. ">"
	end
	return self.name
end

--

function CommandNode.addChild<S>(self: CommandNode<S>, child: CommandNode<S>)
	self.children[child.name] = child
end

function CommandNode.getChild<S>(self: CommandNode<S>, name: string): CommandNode<S>?
	return self.children[name]
end

function CommandNode.canExecute<S>(self: CommandNode<S>): boolean
	return self.command ~= nil
end

return CommandNode