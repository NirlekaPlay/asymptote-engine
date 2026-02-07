--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.world.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local MapCommand = {}

function MapCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("map")
			:andThen(
				CommandHelper.literal("clear")
					:executes(MapCommand.clear)
			)
	)
end

function MapCommand.clear(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	Level.clearLevel()

	c:getSource():sendSuccess(MutableTextComponent.literal("Successfully cleared level"))

	return 1
end

return MapCommand