--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class EntityArgument
]=]
local EntityArgument = {}
EntityArgument.__index = EntityArgument

export type EntityArgument = ArgumentType.ArgumentType<any> & {}

function EntityArgument.entities(): EntityArgument
	return setmetatable({}, EntityArgument) :: EntityArgument
end

function EntityArgument.getEntities(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, name: string): {Instance}
	local parsedEntityArg = context:getArgument(name)
	local source = context:getSource()
	return EntitySelectorParser.resolvePlayerSelector(parsedEntityArg, source:getPlayerOrThrow()) :: { Instance }
end

function EntityArgument.parse(self: EntityArgument, input: string): (any, number)
	local result, consumed = EntitySelectorParser.parse(self, input)
	return result, consumed
end

return EntityArgument