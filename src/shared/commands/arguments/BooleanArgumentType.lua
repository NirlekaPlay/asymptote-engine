--!strict

local BooleanArgumentType = {}

function BooleanArgumentType.parse(input: string): (any, number)
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