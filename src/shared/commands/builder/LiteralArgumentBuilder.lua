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

export type LiteralArgumentBuilder<S> = typeof(setmetatable({} :: {
	literalString: string,
	command: CommandFunction?,
	redirectNode: CommandNode<S>?,
	children: { ArgumentBuilder }
}, LiteralArgumentBuilder))

type ArgumentBuilder = ArgumentBuilder.ArgumentBuilder
type CommandFunction = CommandFunction.CommandFunction
type CommandNode<S> = CommandNode.CommandNode<S>

function LiteralArgumentBuilder.new(literalString: string): LiteralArgumentBuilder<any>
	return setmetatable({
		literalString = literalString,
		command = nil :: CommandFunction?,
		children = {},
		redirectNode = nil :: CommandNode<any>?
	}, LiteralArgumentBuilder)
end

function LiteralArgumentBuilder.executes<S>(self: LiteralArgumentBuilder<S>, commandFunc: CommandFunction): LiteralArgumentBuilder<S>
	self.command = commandFunc
	return self
end

function LiteralArgumentBuilder.andThen<S>(self: LiteralArgumentBuilder<S>, child: ArgumentBuilder): LiteralArgumentBuilder<S>
	table.insert(self.children, child)
	return self
end

function LiteralArgumentBuilder.redirect<S>(self: LiteralArgumentBuilder<S>, target: CommandNode<S>): LiteralArgumentBuilder<S>
	self.redirectNode = target
	return self
end

function LiteralArgumentBuilder.build<S>(self: LiteralArgumentBuilder<S>): CommandNode<S>
	local node = CommandNode.new(self.literalString, "literal", nil)
	node.command = self.command
	node.redirect = self.redirectNode

	if not node.redirect then
		for _, child in self.children do
			node:addChild((child :: any):build())
		end
	end
	
	return node
end

return LiteralArgumentBuilder