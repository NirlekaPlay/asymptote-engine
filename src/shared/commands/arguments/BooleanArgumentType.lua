--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class BooleanArgumentType

	A boolean argument type.
	Which are written exactly as `true` and `false`.
]=]
local BooleanArgumentType = {}
BooleanArgumentType.__index = BooleanArgumentType

-- Since the boolean argument is stateless, we don't really need multiple
-- instances of it. So we only store and return one instance of BooleanArgumentType
-- for memory efficiency.
local BOOL_INST: BooleanArgumentType? = nil

export type BooleanArgumentType = {
	parse: (self: BooleanArgumentType, input: string) -> (boolean, number)
}

function BooleanArgumentType.bool(): BooleanArgumentType
	if not BOOL_INST then
		BOOL_INST = setmetatable({}, BooleanArgumentType) :: BooleanArgumentType
		return BOOL_INST :: any
	end
	return BOOL_INST
end

function BooleanArgumentType.getBool<S>(context: CommandContext.CommandContext<S>, name: string): boolean
	local boolArg = context:getArgument(name)
	if type(boolArg) ~= "boolean" then
		error(`Argument '{name}' results in a value of type {typeof(boolArg)}, expected boolean`)
	end
	return boolArg
end

function BooleanArgumentType.parse(self: BooleanArgumentType, input: string): (boolean, number)
	local word = (input:match("^%S+") :: string):lower()
	
	if word == "true" then
		return true, 4
	elseif word == "false" then
		return false, 5
	else
		error("Expected 'true' or 'false', got: " .. word)
	end
end

return BooleanArgumentType