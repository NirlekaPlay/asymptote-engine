--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DestroyCommand = require(ServerScriptService.server.commands.DestroyCommand)
local ForceFieldCommand = require(ServerScriptService.server.commands.ForceFieldCommand)
local GiveCommand = require(ServerScriptService.server.commands.GiveCommand)
local HelpCommand = require(ServerScriptService.server.commands.HelpCommand)
local HighlightCommand = require(ServerScriptService.server.commands.HighlightCommand)
local KillCommand = require(ServerScriptService.server.commands.KillCommand)
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local SummonCommand = require(ServerScriptService.server.commands.SummonCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local TeleportCommand = require(ServerScriptService.server.commands.TeleportCommand)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

type ArgumentType = ArgumentType.ArgumentType
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
--[=[dispatcher:register(
	LiteralArgumentBuilder.new("foo")
		:andThen(
			RequiredArgumentBuilder.new("bar", Vector3ArgumentType.vec3())
				:executes(function(c)
					local pos = Vector3ArgumentType.resolveAndGetVec3(c, "bar", c:getSource())
					Draw.point(pos)
					--[[local parsedResult = Vector3ArgumentType.getVec3(c, "bar")
					print("Parsed result:", parsedResult)
					local resolvedPosition = Vector3ArgumentType.resolveVec3(parsedResult, c:getSource())
					print("current position:", c:getSource().Character.HumanoidRootPart.Position)
					print("resolved pos:", resolvedPosition)
					Draw.point(resolvedPosition)]]
				end)
		)
)]=]

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)