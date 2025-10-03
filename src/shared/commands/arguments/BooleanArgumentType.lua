--!strict

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
		return setmetatable({}, BooleanArgumentType) :: BooleanArgumentType
	end
	return BOOL_INST
end

function BooleanArgumentType.parse(self: BooleanArgumentType, input: string): (any, number)
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