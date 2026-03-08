--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local LiteralCommandNode = require(ReplicatedStorage.shared.commands.tree.LiteralCommandNode)

local LiteralArgumentBuilder = {}
LiteralArgumentBuilder.__index = LiteralArgumentBuilder

type ArgumentBuilder<S, T> = ArgumentBuilder.ArgumentBuilder<S, T>
type CommandFunction<S> = CommandFunction.CommandFunction<S>
type LiteralCommandNode<S> = LiteralCommandNode.LiteralCommandNode<S>
type Predicate<T> = (T) -> boolean

export type LiteralArgumentBuilder<S> = {
	literalString: string,
	command: CommandFunction<S>?,
	children: { ArgumentBuilder<S, any> },
	redirectNode: LiteralCommandNode<S>?,
	requirement: Predicate<S>?,
	description: string?,
	
	executes: <T>(self: T, commandFunc: CommandFunction<S>) -> T,
	andThen: <T>(self: T, child: ArgumentBuilder<S, any>) -> T,
	redirect: <T>(self: T, target: LiteralCommandNode<S>) -> T,
	build: <T>(self: T) -> LiteralCommandNode<S>,
	requires: <T>(self: T, requirement: Predicate<S>) -> T,
	describe: <T>(self: T, description: string) -> T
}

function LiteralArgumentBuilder.new<S>(literalString: string): LiteralArgumentBuilder<S>
	return setmetatable({
		literalString = literalString,
		command = nil,
		children = {},
		redirectNode = nil
	}, LiteralArgumentBuilder) :: any
end

function LiteralArgumentBuilder.literal<S>(literalString: string): LiteralArgumentBuilder<S>
	return LiteralArgumentBuilder.new(literalString)
end

function LiteralArgumentBuilder.describe<S>(self: LiteralArgumentBuilder<S>, description: string): LiteralArgumentBuilder<S>
	self.description = description
	return self
end

function LiteralArgumentBuilder.executes<S>(self: LiteralArgumentBuilder<S>, commandFunc: CommandFunction<S>)
	self.command = commandFunc
	return self
end

function LiteralArgumentBuilder.requires<S>(self: LiteralArgumentBuilder<S>, predicate: Predicate<S>): LiteralArgumentBuilder<S>
	self.requirement = predicate
	return self
end

function LiteralArgumentBuilder.andThen<S>(self: LiteralArgumentBuilder<S>, child: ArgumentBuilder<S, any>)
	table.insert(self.children, child)
	return self
end

function LiteralArgumentBuilder.redirect<S>(self: LiteralArgumentBuilder<S>, target: LiteralCommandNode<S>)
	self.redirectNode = target
	return self
end

function LiteralArgumentBuilder.build<S>(self: LiteralArgumentBuilder<S>): LiteralCommandNode<S>
	local node = LiteralCommandNode.new(self.literalString, self.command, self.requirement, self.redirectNode, self.description)
	local redirectNode = self.redirectNode
	if redirectNode then
		node.redirect = redirectNode
	end

	if not node.redirect then
		for _, child in self.children do
			node:addChild(child:build())
		end
	end

	return node
end

return LiteralArgumentBuilder