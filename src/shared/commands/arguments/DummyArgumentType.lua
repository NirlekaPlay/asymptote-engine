--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class DummyArgumentType

	This module serves as your blank canvas for making a new
	argument type.
	Make sure to correctly type the `any` types and replace the
	`DummyArgumentType` name in the entire file to your
	argument type name.
]=]
local DummyArgumentType = {}
DummyArgumentType.__index = DummyArgumentType

export type DummyArgumentType = ArgumentType.ArgumentType<any> & {}

function DummyArgumentType.dummy(): DummyArgumentType
	return {} :: any
end

function DummyArgumentType.getDummy<S>(context: CommandContext.CommandContext<S>, name: string): any
	return {}
end

function DummyArgumentType.parse(self: DummyArgumentType, input: string): (any, number)
	return {}
end

return DummyArgumentType