--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local ArgumentCommandNode = require(ReplicatedStorage.shared.commands.tree.ArgumentCommandNode)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local LiteralCommandNode = require(ReplicatedStorage.shared.commands.tree.LiteralCommandNode)

--[=[
	@class ArgumentBuilderFactory

	In **Brigadier**, creating a builder from a `CommandNode` itself can be done by directly calling
	`createBuilder` on the node. However, this creates a circular dependency between the builder and the node.
	To resolve this, the `ArgumentBuilderFactory` serves as a centralized place to create the builders
	for their respective nodes.
]=]
local ArgumentBuilderFactory = {}

type ArgumentBuilder<S, T> = ArgumentBuilder.ArgumentBuilder<S, T>
type ArgumentCommandNode<S> = ArgumentCommandNode.ArgumentCommandNode<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type LiteralCommandNode<S> = LiteralCommandNode.LiteralCommandNode<S>
type LiteralArgumentBuilder<S> = LiteralArgumentBuilder.LiteralArgumentBuilder<S>
type RequiredArgumentBuilder<S> = RequiredArgumentBuilder.RequiredArgumentBuilder<S>

function ArgumentBuilderFactory.createBuilder<S>(node: CommandNode<S>): ArgumentBuilder<S, any>
	if node:getNodeType() == CommandNodeType.ROOT then
		error("Cannot convert root into a builder")
	elseif node:getNodeType() == CommandNodeType.LITERAL then
		return ArgumentBuilderFactory.createLiteralBuilder(node :: any)
	elseif node:getNodeType() == CommandNodeType.ARGUMENT then
		return ArgumentBuilderFactory.createRequiredBuilder(node :: any)
	else
		error("Unknown CommandNodeType: " .. tostring(node:getNodeType()))
	end
end

--

function ArgumentBuilderFactory.createLiteralBuilder<S>(node: LiteralCommandNode<S>): LiteralArgumentBuilder<S>
	local builder = LiteralArgumentBuilder.literal(node:getName())
	if node:getRequirement() then
		builder:requires(node:getRequirement() :: any)
	end
	if node:getRedirect() then
		builder:redirect(node:getRedirect())
	end
	return builder
end

function ArgumentBuilderFactory.createRequiredBuilder<S>(node: ArgumentCommandNode<S>): RequiredArgumentBuilder<S>
	local builder = RequiredArgumentBuilder.argument(node:getName(), node:getArgumentType())
	if node:getRequirement() then
		builder:requires(node:getRequirement() :: any)
	end
	if node:getRedirect() then
		builder:redirect(node:getRedirect())
	end
	if node:getCustomSuggestions() then
		builder:suggests(node:getCustomSuggestions())
	end
	if node:getCommand() ~= nil then
		builder:executes(node:getCommand())
	end
	return builder
end

return ArgumentBuilderFactory