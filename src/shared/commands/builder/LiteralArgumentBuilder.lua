--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local LiteralArgumentBuilder = {}
LiteralArgumentBuilder.__index = LiteralArgumentBuilder

type ArgumentBuilder<S, T> = ArgumentBuilder.ArgumentBuilder<S, T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>

export type LiteralArgumentBuilder<S> = {
	literalString: string,
	command: CommandFunction<S>?,
	children: { ArgumentBuilder<S, any> },
	redirectNode: CommandNode<S>?,
	
	executes: <T>(self: T, commandFunc: CommandFunction<S>) -> T,
	andThen: <T>(self: T, child: ArgumentBuilder<S, any>) -> T,
	redirect: <T>(self: T, target: CommandNode<S>) -> T,
	build: <T>(self: T) -> CommandNode<S>
}

function LiteralArgumentBuilder.new<S>(literalString: string): LiteralArgumentBuilder<S>
	return setmetatable({
		literalString = literalString,
		command = nil,
		children = {},
		redirectNode = nil
	}, LiteralArgumentBuilder) :: any
end

function LiteralArgumentBuilder.executes<S>(self: LiteralArgumentBuilder<S>, commandFunc: CommandFunction<S>)
	self.command = commandFunc
	return self
end

function LiteralArgumentBuilder.andThen<S>(self: LiteralArgumentBuilder<S>, child: ArgumentBuilder<S, any>)
	table.insert(self.children, child)
	return self
end

function LiteralArgumentBuilder.redirect<S>(self: LiteralArgumentBuilder<S>, target: CommandNode<S>)
	self.redirectNode = target
	return self
end

function LiteralArgumentBuilder.build<S>(self: LiteralArgumentBuilder<S>): CommandNode<S>
	local node = CommandNode.new(self.literalString, "literal", nil)
	node.command = self.command
	node.redirect = self.redirectNode
	
	if not node.redirect then
		for _, child in self.children do
			node:addChild(child:build())
		end
	end
	
	return node
end

return LiteralArgumentBuilder