--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.world.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local TickCommand = {}

function TickCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("tick")
			:andThen(
				CommandHelper.literal("freeze")
					:executes(function(c)
						return TickCommand.freezeWorldUpdate(c)
					end)
			)
			:andThen(
				CommandHelper.literal("unfreeze")
					:executes(function(c)
						return TickCommand.unfreezeWorldUpdate(c)
					end)
			)
	)
end

function TickCommand.freezeWorldUpdate(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	Level.setCanUpdateWorld(false)
	c:getSource():sendSuccess(MutableTextComponent.literal("Successfully stop world update"))
	return 1
end

function TickCommand.unfreezeWorldUpdate(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	Level.setCanUpdateWorld(true)
	c:getSource():sendSuccess(MutableTextComponent.literal("World update will now run normally"))
	return 1
end

return TickCommand