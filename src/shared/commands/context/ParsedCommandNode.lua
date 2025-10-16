--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local ParsedCommandNode = {}
ParsedCommandNode.__index = ParsedCommandNode

export type ParsedCommandNode<S> = typeof(setmetatable({} :: {
	node: CommandNode.CommandNode<S>,
	range: StringRange.StringRange
}, ParsedCommandNode))

function ParsedCommandNode.new<S>(node: CommandNode.CommandNode<S>, range: StringRange.StringRange): ParsedCommandNode<S>
	return setmetatable({
		node = node,
		range = range
	}, ParsedCommandNode)
end

function ParsedCommandNode.getNode<S>(self: ParsedCommandNode<S>): T
	return self.node
end

function ParsedCommandNode.getRange<S>(self: ParsedCommandNode<S>): StringRange.StringRange
	return self.range
end

return ParsedCommandNode