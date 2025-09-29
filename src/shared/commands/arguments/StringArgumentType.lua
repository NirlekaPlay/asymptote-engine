--!strict

local StringArgumentType = {}

function StringArgumentType.parse(input: string): (any, number)
	local word = input:match("^%S+")
	if word then
		return word, word:len()
	end
	error("Expected string argument")
end

return StringArgumentType