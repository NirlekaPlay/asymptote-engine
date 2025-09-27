--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

--[=[
	@class LiteralArgumentBuilder
]=]
local LiteralArgumentBuilder = {}
LiteralArgumentBuilder.__index = LiteralArgumentBuilder

export type LiteralArgumentBuilder = typeof(setmetatable({} :: {
	literalString: string,
	command: CommandFunction?,
	children: { ArgumentBuilder }
}, LiteralArgumentBuilder))

type ArgumentBuilder = ArgumentBuilder.ArgumentBuilder
type CommandFunction = CommandFunction.CommandFunction
type CommandNode = CommandNode.CommandNode

function LiteralArgumentBuilder.new(literalString: string): LiteralArgumentBuilder
	return setmetatable({
		literalString = literalString,
		command = nil :: CommandFunction?,
		children = {}
	}, LiteralArgumentBuilder)
end

function LiteralArgumentBuilder.executes(self: LiteralArgumentBuilder, commandFunc: CommandFunction): ArgumentBuilder
	self.command = commandFunc
	return self :: ArgumentBuilder
end

function LiteralArgumentBuilder.andThen(self: LiteralArgumentBuilder, child: ArgumentBuilder): ArgumentBuilder
	table.insert(self.children, child)
	return self :: ArgumentBuilder
end

function LiteralArgumentBuilder.build(self: LiteralArgumentBuilder): CommandNode
	local node = CommandNode.new(self.literalString, "literal", nil)
	node.command = self.command
	
	for _, child in self.children do
		node:addChild(child:build())
	end
	
	return node
end

return LiteralArgumentBuilder