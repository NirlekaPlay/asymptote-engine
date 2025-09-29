--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)

local RestartServerCommand = {}

function RestartServerCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("restartserver")
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