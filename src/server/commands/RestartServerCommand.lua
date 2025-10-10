--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
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
	if #Players:GetPlayers() == 0 then
		return
	end
	
	local reservedServerCode = TeleportService:ReserveServer(game.PlaceId)

	for _, player in ipairs(Players:GetPlayers()) do
		TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, {player})
	end

	Players.PlayerAdded:Connect(function(player)
		TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, {player})
	end)
end

return RestartServerCommand