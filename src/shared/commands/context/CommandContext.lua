--!strict

--[=[
	@class CommandContext
]=]
local CommandContext = {}
CommandContext.__index = CommandContext

export type CommandContext = typeof(setmetatable({} :: {
	arguments: { [string]: any },
	source: any
}, CommandContext))

function CommandContext.new(arguments: { [string]: any }, source: any): CommandContext
	return setmetatable({
		arguments = arguments,
		source = source
	}, CommandContext)
end

function CommandContext.getArgument(self: CommandContext, name: string): ()
	return self.arguments[name]
end

function CommandContext.getSource(self: CommandContext): any
	return self.source
end

return CommandContext