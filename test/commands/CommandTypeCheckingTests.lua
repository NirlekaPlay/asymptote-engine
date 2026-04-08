--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local literal = LiteralArgumentBuilder.new :: (literal: string) -> LiteralArgumentBuilder.LiteralArgumentBuilder<CommandSourceStack.CommandSourceStack>
local argument = RequiredArgumentBuilder.new :: <T>(name: string, arg: ArgumentType.ArgumentType<T>) -> RequiredArgumentBuilder.RequiredArgumentBuilder<CommandSourceStack.CommandSourceStack, T>

local dispatcher = (CommandDispatcher.new() :: any) :: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>

local summonCommand = literal("summon")
	:andThen(
		argument("entity", StringArgumentType.string())
			:executes(function(context): number
				return 1
			end)
			:andThen(
				argument("pos", Vector3ArgumentType.vec3())
					:executes(function(context)
						return 1
					end)
					:andThen(
						argument("nbt", JsonArgumentType.jsonObject())
							:executes(function(context)
								return 1
							end)
					)
			)
	)

dispatcher:register(summonCommand)

local parsed = dispatcher:parseString('summon npc 1 2 3 {"CharName": "Luca"}')
print(parsed)

return 0