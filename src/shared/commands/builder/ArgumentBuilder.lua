--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)


export type ArgumentBuilder<S> = {
	command: CommandFunction<S>?,
	redirectNode: CommandNode<S>?,
	children: { ArgumentBuilder<S> },
	--
	executes: (self: ArgumentBuilder<S>, command: CommandFunction<S>) -> ArgumentBuilder<S>,
	andThen: (self: ArgumentBuilder<S>, child: ArgumentBuilder<S>) -> ArgumentBuilder<S>,
	redirect: (self: ArgumentBuilder<S>, target: CommandNode<S>) -> ArgumentBuilder<S>,
	build: (self: ArgumentBuilder<S>) -> CommandNode<S>
}

type CommandFunction<S> = CommandFunction.CommandFunction<S>
type CommandNode<S> = CommandNode.CommandNode<S>

return nil