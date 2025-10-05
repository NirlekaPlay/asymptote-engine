--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local dispatcher = CommandDispatcher.new() :: CommandDispatcher.CommandDispatcher<Player>

local literal = LiteralArgumentBuilder.new :: () -> LiteralArgumentBuilder.LiteralArgumentBuilder<Player>
local argument = RequiredArgumentBuilder.new :: <T>(argName: string, argType: ArgumentType.ArgumentType<T>) -> RequiredArgumentBuilder.RequiredArgumentBuilder<Player>

--[=[
	This is a type test.

	Definitions.
	 a. `<T>` should be the type of the *source* of the executor.

	Expected behaviors:

	 a. No type errors under `--!strict` directive.
	 b. Context variable under `:executes()` function should be typed as `CommandContext`.
	 c. The value of the result of `context:getSource()` should be of type `<T>`.
]=]

dispatcher:register(
	literal("a")
		:executes(function(context)
			local _source = context:getSource()
			return 1
		end)

		:andThen(
			literal("b")
				:executes(function()
					return 1
				end)
		)

		:andThen(
			argument("x", IntegerArgumentType.integer())
				:executes(function()
					return 1
				end)

				:andThen(
					argument("y", IntegerArgumentType.integer())
						:executes(function()
							return 1
						end)
				)
		)
)