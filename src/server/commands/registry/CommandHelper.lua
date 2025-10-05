--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local CommandHelper = {}

function CommandHelper.literal(literalString: string): LiteralArgumentBuilder.LiteralArgumentBuilder<CommandSourceStack.CommandSourceStack>
	return LiteralArgumentBuilder.new(literalString) :: any
end

function CommandHelper.argument<T>(name: string, argumentType: ArgumentType.ArgumentType<T>): ArgumentBuilder.ArgumentBuilder<CommandSourceStack.CommandSourceStack>
	return RequiredArgumentBuilder.new(name, argumentType) :: any
end

return CommandHelper