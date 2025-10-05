--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local CommandSource = require(ServerScriptService.server.commands.source.CommandSource)

--[=[
	@class CommandSourceStack
]=]
local CommandSourceStack = {}
CommandSourceStack.__index = CommandSourceStack

export type CommandSourceStack = typeof(setmetatable({} :: {
	source: CommandSource.CommandSource,
	entity: Instance,
	position: Vector3,
	displayName: string,
	textName: string
}, CommandSourceStack))

function CommandSourceStack.new(
	source: CommandSource.CommandSource,
	entity: Instance,
	position: Vector3,
	displayName: string,
	textName: string
): CommandSourceStack
	return setmetatable({
		source = source,
		entity = entity,
		position = position,
		displayName = displayName,
		textName = textName
	}, CommandSourceStack)
end

function CommandSourceStack.getPlayerOrThrow(self: CommandSourceStack): Player
	if self.entity:IsA("Player") then
		return self.entity
	else
		error("CommandSourceStack.getPlayerOrThrow() failure: Entity is not of type Player.")
	end
end

return CommandSourceStack