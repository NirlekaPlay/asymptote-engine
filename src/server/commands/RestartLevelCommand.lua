--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
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
	local level = c:getSource():getLevel()
	if level then
		c:getSource():sendFailure(
			MutableTextComponent.literal("Cannot restart scene: Scene is already restarting.")
		)
	end

	level:restartScene()

	c:getSource():sendSuccess(
		MutableTextComponent.literal("Scene restarted successfully.")
	)
end

return RestartLevelCommand