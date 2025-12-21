--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.world.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local RestartLevelCommand = {}

function RestartLevelCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("restartlevel")
			:executes(function(c)
				RestartLevelCommand.restartServer(c)
				return 1
			end)
	)
end

function RestartLevelCommand.restartServer(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): ()
	if Level.isRestarting() then
		c:getSource():sendFailure(
			MutableTextComponent.literal("Cannot restart level: Level is already restarting.")
		)
	end

	Level.restartLevel()

	c:getSource():sendSuccess(
		MutableTextComponent.literal("Level restarted successfully.")
	)
end

return RestartLevelCommand