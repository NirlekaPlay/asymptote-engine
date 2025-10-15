--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ParsedArgument = require(ReplicatedStorage.shared.commands.context.ParsedArgument)
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)

--[=[
	@class CommandNode
]=]
local CommandNode = {}
CommandNode.__index = CommandNode

export type CommandNode<S> = typeof(setmetatable({} :: {
	name: string,
	nodeType: "literal" | "argument",
	requirement: Predicate<S>?,
	redirect: CommandNode<S>,
	argumentType: ArgumentType<any>,
	command: CommandFunction<S>,
	children: { [string]: CommandNode<S> }
}, CommandNode))

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type Predicate<T> = (T) -> boolean

function CommandNode.new<S>(name: string, nodeType: "literal" | "argument", argumentType: ArgumentType<any>, requirement: Predicate<S>?, redirect: CommandNode<S>): CommandNode<S>
	return setmetatable({
		name = name,
		nodeType = nodeType,
		requirement = requirement,
		redirect = redirect,
		argumentType = argumentType,
		command = nil :: any,
		children = {}
	}, CommandNode)
end

function CommandNode.getCommand<S>(self: CommandNode<S>): CommandFunction<S>
	return self.command
end

function CommandNode.getRedirect<S>(self: CommandNode<S>): CommandNode<S>?
	return self.redirect
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

function CommandNode.parse<S>(self: CommandNode<S>, reader: StringReader.StringReader, contextBuilder: CommandContextBuilder.CommandContextBuilder<S>): () -- ANOTHER FUCKING CIRUCLAR DEPENDENCY BULLSHIT
	if self.nodeType == "literal" then
		return self:parseLiteral(reader, contextBuilder)
	elseif self.nodeType == "argument" then
		return self:parseArgument(reader, contextBuilder)
	else
		error("Invalid node type:", self.nodeType)
	end
end

function CommandNode.parseLiteral<S>(self: CommandNode<S>, reader: StringReader.StringReader, contextBuilder: CommandContextBuilder.CommandContextBuilder<S>): ()
	local startPos = reader:getCursorPos()
	local endPos = self:parseLiteralEnd(reader)
	if endPos > -1 then
		
		contextBuilder:withNode(self, StringRange.between(startPos, endPos))
		return
	end

	error("LITERAL_INCORRECT")
end

function CommandNode.parseLiteralEnd<S>(self: CommandNode<S>, reader: StringReader.StringReader): number
	local literal = self.name
	local startPos = reader:getCursorPos()
	local literalLength = utf8.len(literal) :: number
	if reader:canRead(literalLength) then
		local endPos = startPos + literalLength
		if table.concat(reader:getEncompassingChars(startPos, endPos)) == literal then
			reader:setCursorPos(endPos)
			if not reader:canRead() or reader:peek() == ' ' then
				return endPos
			else
				reader:setCursorPos(startPos)
			end
		end
	end

	return -1
end

function CommandNode.parseArgument<S>(self: CommandNode<S>, reader: StringReader.StringReader, contextBuilder: CommandContextBuilder.CommandContextBuilder<S>): ()
	local startPos = reader:getCursorPos()
	local remaining = reader:getRemaining()
	
	local result, consumed = self.argumentType:parse(remaining)
	reader:setCursorPos(startPos + consumed)
	local parsed = ParsedArgument.new(startPos, reader:getCursorPos(), result)
	contextBuilder:withArgument(self.name, parsed)
	contextBuilder:withNode(self, parsed:getRange())
end

function CommandNode.getRelevantNodes<S>(self: CommandNode<S>, input: StringReader.StringReader): { CommandNode<S> }
	local numOfLiteralChildren = 0
	local argumentChildren: { CommandNode<S> } = {}
	for _, node in pairs(self.children) do
		if node.nodeType == "literal" then
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
		if literal and literal.nodeType == "literal" then
			return {literal}
		else
			return argumentChildren
		end
	else
		return argumentChildren
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