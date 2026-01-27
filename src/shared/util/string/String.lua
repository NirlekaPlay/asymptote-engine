--!strict

local PATTERN_WHITESPACE = "%S+"

local table_insert = table.insert
local string_gmatch = string.gmatch

--[=[
	@class String

	A set of utility functions to handle standard Luau strings.
	If you want a more Unicode aware way to handle string operations, see `UString`.
]=]
local String = {}

--[=[
	Returns an array of all non-whitespace sequences found in `str`.
]=]
function String.splitByWhitespace(str: string): {string}
	local words = {}

	for word in string_gmatch(str, PATTERN_WHITESPACE) do
		table_insert(words, word)
	end
	
	return words
end

return String