--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)

--[=[
	@class CommandContext
]=]
local CommandContext = {}
CommandContext.__index = CommandContext

export type CommandContext<S> = typeof(setmetatable({} :: {
	arguments: { [string]: any },
	source: S,
	range: StringRange.StringRange,
	child: CommandContext<S>
}, CommandContext))

function CommandContext.new<S>(
	arguments: { [string]: any },
	source: S,
	child: CommandContext<S>,
	range: StringRange.StringRange
): CommandContext<S>

	return setmetatable({
		arguments = arguments,
		source = source,
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