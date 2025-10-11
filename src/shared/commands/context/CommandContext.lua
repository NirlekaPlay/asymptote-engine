--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParsedArgument = require(ReplicatedStorage.shared.commands.context.ParsedArgument)
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)

--[=[
	@class CommandContext
]=]
local CommandContext = {}
CommandContext.__index = CommandContext

export type CommandContext<S> = typeof(setmetatable({} :: {
	source: S,
	input: string,
	arguments: { [string]: ParsedArgument.ParsedArgument<S, any> },
	command: CommandFunction<S>,
	rootNode: CommandNode.CommandNode, -- CIRCULAR DEPENDENCY BULLSHIT WTF WHY
	nodes: { ParsedCommandNode.ParsedCommandNode<S> }, -- ANOTHER CIRCULAR DEPENDENCY, CANT WE JUST GET THE FUCKING TYPES IN PEACE
	range: StringRange.StringRange,
	child: CommandContext<S>
}, CommandContext))

type CommandFunction<S> = (context: CommandContext<S>) -> number -- to avoid circular dependency bullshit

function CommandContext.new<S>(
	source: S,
	input: string,
	arguments: { [string]: ParsedArgument.ParsedArgument<S, any> },
	command: CommandFunction<S>,
	rootNode: CommandNode.CommandNode,
	nodes: { ParsedCommandNode.ParsedCommandNode<S> },
	range: StringRange.StringRange,
	child: CommandContext<S>
): CommandContext<S>

	return setmetatable({
		source = source,
		input = input,
		arguments = arguments,
		command = command,
		rootNode = rootNode,
		nodes = nodes,
		range = range,
		child = child
	}, CommandContext)
end

function CommandContext.getArgument<S>(self: CommandContext<S>, name: string): any
	local argument = self.arguments[name]
	if argument == nil then
		error(`No such argument '{name}' exists on this command.`)
	end
	return argument
end

function CommandContext.getSource<S>(self: CommandContext<S>): S
	return self.source
end

function CommandContext.getRange<S>(self: CommandContext<S>): StringRange.StringRange
	return self.range
end

function CommandContext.getChild<S>(self: CommandContext<S>): CommandContext<S>
	return self.child
end

return CommandContext