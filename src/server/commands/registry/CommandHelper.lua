--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local CommandHelper = {}

function CommandHelper.literal(literalString: string): LiteralArgumentBuilder.LiteralArgumentBuilder<CommandSourceStack.CommandSourceStack>
	return LiteralArgumentBuilder.new(literalString) :: any
end

CommandHelper.argument = RequiredArgumentBuilder.new :: <T>(argName: string, argType: ArgumentType.ArgumentType<T>) -> RequiredArgumentBuilder.RequiredArgumentBuilder<CommandSourceStack.CommandSourceStack>

return CommandHelper