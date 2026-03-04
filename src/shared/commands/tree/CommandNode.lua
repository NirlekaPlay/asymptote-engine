--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local SuggestionProvider = require(ReplicatedStorage.shared.commands.suggestion.SuggestionProvider)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)

--[=[
	@class CommandNode
]=]
local CommandNode = {}
CommandNode.__index = CommandNode

export type CommandNode<S> = typeof(setmetatable({} :: {
	name: string,
	literalLowerCase: string,
	nodeType: "literal" | "argument",
	requirement: Predicate<S>?,
	redirect: CommandNode<S>,
	argumentType: ArgumentType<any>,
	command: CommandFunction<S>,
	children: { [string]: CommandNode<S> },
	customSuggestions: SuggestionProvider.SuggestionProvider<S>?,
	getNodeType: (self: CommandNode<S>) -> number
}, CommandNode))

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type Predicate<T> = (T) -> boolean

function CommandNode.new<S>(name: string, nodeType: "literal" | "argument", argumentType: ArgumentType<any>, requirement: Predicate<S>?, redirect: CommandNode<S>, suggestions: SuggestionProvider.SuggestionProvider<S>?): CommandNode<S>
	return setmetatable({
		name = name,
		literalLowerCase = name:lower(),
		nodeType = nodeType,
		requirement = requirement,
		redirect = redirect,
		argumentType = argumentType,
		command = nil :: any,
		children = {},
		customSuggestions = suggestions
	}, CommandNode)
end

function CommandNode.getCommand<S>(self: CommandNode<S>): CommandFunction<S>
	return self.command
end

function CommandNode.getRedirect<S>(self: CommandNode<S>): CommandNode<S>?
	return self.redirect
end

function CommandNode.getRequirement<S>(self: CommandNode<S>): Predicate<S>?
	return self.requirement
end

function CommandNode.getChildren<S>(self: CommandNode<S>): { [string]: CommandNode<S> }
	return self.children
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

function CommandNode.getRelevantNodes<S>(self: CommandNode<S>, input: StringReader.StringReader): { CommandNode<S> }
	local numOfLiteralChildren = 0
	local argumentChildren: { CommandNode<S> } = {}
	for _, node in pairs(self.children) do
		if node:getNodeType() == CommandNodeType.LITERAL then
			numOfLiteralChildren += 1
		else
			table.insert(argumentChildren, node)
		end
	end
	
	if numOfLiteralChildren > 0 then
		local cursor = input:getCursorPos()
		while input:canRead() and input:peek() ~= ' ' do
			input:skip()
		end
		local text = table.concat(input:getEncompassingChars(cursor, input:getCursorPos()))
		input:setCursorPos(cursor)
		
		local literal = self.children[text]
		if literal and literal:getNodeType() == CommandNodeType.LITERAL then
			return {literal}
		else
			return argumentChildren
		end
	else
		return argumentChildren
	end
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