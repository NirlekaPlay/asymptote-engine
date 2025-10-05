--!strict

--[=[
	@class CommandContext
]=]
local CommandContext = {}
CommandContext.__index = CommandContext

export type CommandContext<S> = typeof(setmetatable({} :: {
	arguments: { [string]: any },
	source: S
}, CommandContext))

function CommandContext.new<S>(arguments: { [string]: any }, source: S): CommandContext<S>
	return setmetatable({
		arguments = arguments,
		source = source
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

return CommandContext