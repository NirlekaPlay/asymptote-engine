--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local ParseResults = {}
ParseResults.__index = ParseResults

export type ParseResults<S> = typeof(setmetatable({} :: {
	context: CommandContext.CommandContext<S>,
	errors: { [CommandNode.CommandNode<S>]: string },
	remaining: string
}, ParseResults))

function ParseResults.new<S>(
	context: CommandContext.CommandContext<S>,
	errors: { [CommandNode.CommandNode<S>]: string },
	remaining: string
): ParseResults<S>
	return setmetatable({
		context = context,
		errors = errors,
		remaining = remaining
	}, ParseResults)
end

function ParseResults.getContext<S>(self: ParseResults<S>): CommandContext.CommandContext<S>
	return self.context
end

function ParseResults.getErrors<S>(self: ParseResults<S>): { [CommandNode.CommandNode<S>]: string }
	return self.errors
end

function ParseResults.getRemaining<S>(self: ParseResults<S>): string
	return self.remaining
end

return ParseResults