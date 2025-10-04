--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CellCommand = require(ServerScriptService.server.commands.CellCommand)
local DestroyCommand = require(ServerScriptService.server.commands.DestroyCommand)
local ForceFieldCommand = require(ServerScriptService.server.commands.ForceFieldCommand)
local GiveCommand = require(ServerScriptService.server.commands.GiveCommand)
local HelpCommand = require(ServerScriptService.server.commands.HelpCommand)
local HighlightCommand = require(ServerScriptService.server.commands.HighlightCommand)
local KillCommand = require(ServerScriptService.server.commands.KillCommand)
local QuoteOfTheDayCommand = require(ServerScriptService.server.commands.QuoteOfTheDayCommand)
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local SummonCommand = require(ServerScriptService.server.commands.SummonCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local TeleportCommand = require(ServerScriptService.server.commands.TeleportCommand)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

type CommandContext<S> = CommandContext.CommandContext<S>
type CommandDispatcher<S> = CommandDispatcher.CommandDispatcher<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CommandFunction = CommandFunction.CommandFunction

local dispatcher: CommandDispatcher<Player> = CommandDispatcher.new()

RestartServerCommand.register(dispatcher)
TagCommand.register(dispatcher)
KillCommand.register(dispatcher)
TeleportCommand.register(dispatcher)
HighlightCommand.register(dispatcher)
DestroyCommand.register(dispatcher)
ForceFieldCommand.register(dispatcher)
SummonCommand.register(dispatcher)
GiveCommand.register(dispatcher)
HelpCommand.register(dispatcher)
QuoteOfTheDayCommand.register(dispatcher)
CellCommand.register(dispatcher)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)