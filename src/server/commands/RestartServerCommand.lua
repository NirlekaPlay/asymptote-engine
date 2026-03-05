--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local SoftShutdown = require(ServerScriptService.server.teleportation.SoftShutdown)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)

local RestartServerCommand = {}

function RestartServerCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("restartserver")
			:executes(function(c)
				RestartServerCommand.restartServer()
				return 1
			end)
	)
end

function RestartServerCommand.restartServer(): ()
	SoftShutdown.shutdown()
end

return RestartServerCommand