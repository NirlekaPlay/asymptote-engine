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

export type LiteralArgumentBuilder<S> = {
	literalString: string,
	command: CommandFunction<S>?,
	redirectNode: CommandNode<S>?,
	children: { ArgumentBuilder<S> },
	--
	executes: (self: LiteralArgumentBuilder<S>, command: CommandFunction<S>) -> LiteralArgumentBuilder<S>,
	andThen: (self: LiteralArgumentBuilder<S>, child: ArgumentBuilder<S>) -> LiteralArgumentBuilder<S>,
	redirect: (self: LiteralArgumentBuilder<S>, target: CommandNode<S>) -> LiteralArgumentBuilder<S>,
	build: (self: LiteralArgumentBuilder<S>) -> CommandNode<S>
}

type ArgumentBuilder<S> = ArgumentBuilder.ArgumentBuilder<S>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>

function LiteralArgumentBuilder.new<S>(literalString: string): LiteralArgumentBuilder<S>
	return setmetatable({
		literalString = literalString,
		command = nil :: CommandFunction<S>?,
		children = {},
		redirectNode = nil :: CommandNode<S>?
	}, LiteralArgumentBuilder) :: LiteralArgumentBuilder<S>
end

function LiteralArgumentBuilder.executes<S>(self: LiteralArgumentBuilder<S>, commandFunc: CommandFunction<S>): LiteralArgumentBuilder<S>
	self.command = commandFunc
	return self
end

function LiteralArgumentBuilder.andThen<S>(self: LiteralArgumentBuilder<S>, child: ArgumentBuilder<S>): LiteralArgumentBuilder<S>
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