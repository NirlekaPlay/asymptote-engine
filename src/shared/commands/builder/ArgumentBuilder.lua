--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

--[=[
	@class ArgumentBuilder
]=]
local ArgumentBuilder = {}
ArgumentBuilder.__index = ArgumentBuilder

export type ArgumentBuilder = typeof(setmetatable({} :: {
	executes: (self: ArgumentBuilder, command: CommandFunction) -> ArgumentBuilder,
	andThen: (self: ArgumentBuilder, child: ArgumentBuilder) -> ArgumentBuilder,
	build: (self: ArgumentBuilder) -> CommandNode
}, ArgumentBuilder))

type CommandFunction = CommandFunction.CommandFunction
type CommandNode = CommandNode.CommandNode

return ArgumentBuilder