--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

export type ArgumentBuilder<S, T> = {
	command: CommandFunction<S>?,
	redirectNode: CommandNode<S>?,
	children: { ArgumentBuilder<S, T> },
	--
	executes: (self: T, command: CommandFunction<S>) -> T,
	andThen: (self: T, child: ArgumentBuilder<S, T>) -> T,
	redirect: (self: T, target: CommandNode<S>) -> T,
	build: (self: T) -> CommandNode<S>
}

type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>

return nil