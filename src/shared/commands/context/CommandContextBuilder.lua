--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local ParsedArgument = require(ReplicatedStorage.shared.commands.context.ParsedArgument)
local ParsedCommandNode = require(ReplicatedStorage.shared.commands.context.ParsedCommandNode)
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local CommandContextBuilder = {}
CommandContextBuilder.__index = CommandContextBuilder

export type CommandContextBuilder<S> = typeof(setmetatable({} :: {
	arguments: { [string]: ParsedArgument.ParsedArgument<S, any> },
	rootNode: CommandNode.CommandNode<S>,
	nodes: { ParsedCommandNode.ParsedCommandNode<S> },
	source: S,
	command: CommandFunction.CommandFunction<S>?,
	child: CommandContextBuilder<S>?,
	range: StringRange.StringRange
}, CommandContextBuilder))

function CommandContextBuilder.new<S>(source: S, rootNode: CommandNode.CommandNode<S>, startPos: number): CommandContextBuilder<S>
	return setmetatable({
		arguments = {},
		rootNode = rootNode,
		nodes = {},
		source = source,
		command = nil :: CommandFunction.CommandFunction<S>?,
		child = nil :: CommandContextBuilder<S>?,
		range = StringRange.at(startPos)
	}, CommandContextBuilder)
end

function CommandContextBuilder.withSource<S>(self: CommandContextBuilder<S>, source: S): CommandContextBuilder<S>
	self.source = source
	return self
end

function CommandContextBuilder.getSource<S>(self: CommandContextBuilder<S>): S
	return self.source
end

function CommandContextBuilder.getRange<S>(self: CommandContextBuilder<S>): StringRange.StringRange
	return self.range
end

function CommandContextBuilder.getNodes<S>(self: CommandContextBuilder<S>): { ParsedCommandNode.ParsedCommandNode<S> }
	return self.nodes
end

function CommandContextBuilder.getRootNode<S>(self: CommandContextBuilder<S>): CommandNode.CommandNode<S>
	return self.rootNode
end

function CommandContextBuilder.withArgument<S>(self: CommandContextBuilder<S>, name: string, argument: ParsedArgument.ParsedArgument<S, any>): CommandContextBuilder<S>
	self.arguments[name] = argument
	return self
end

function CommandContextBuilder.getArguments<S>(self: CommandContextBuilder<S>): { [string]: ParsedArgument.ParsedArgument<S, any> }
	return self.arguments
end

function CommandContextBuilder.withCommand<S>(self: CommandContextBuilder<S>, command: CommandFunction.CommandFunction<S>): CommandContextBuilder<S>
	self.command = command
	return self
end

function CommandContextBuilder.withNode<S>(self: CommandContextBuilder<S>, node: CommandNode.CommandNode<S>, range: StringRange.StringRange): CommandContextBuilder<S>
	table.insert(self.nodes, ParsedCommandNode.new(node, range))
	self.range = StringRange.encompassing(self.range, range)
	return self
end

function CommandContextBuilder.withChild<S>(self: CommandContextBuilder<S>, child: CommandContextBuilder<S>): CommandContextBuilder<S>
	self.child = child
	return self
end

function CommandContextBuilder.copy<S>(self: CommandContextBuilder<S>): CommandContextBuilder<S>
	local copy = CommandContextBuilder.new(
		self.source,
		self.rootNode,
		self.range:getStart()
	)
	copy.command = self.command
	copy.child = self.child
	copy.range = self.range
	for name, arg in self.arguments do
		copy.arguments[name] = arg
	end
	for i, node in self.nodes do
		copy.nodes[i] = node
	end
	return self
end

function CommandContextBuilder.build<S>(self: CommandContextBuilder<S>, input: string): CommandContext.CommandContext<S>
	return CommandContext.new(
		self.source,
		input,
		self.arguments,
		self.command :: any,
		self.rootNode,
		self.nodes,
		self.range,
		if self.child then self.child:build() else nil
	)
end

return CommandContextBuilder