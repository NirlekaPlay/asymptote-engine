--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class StringArgumentType

	A string argument type.
]=]
local StringArgumentType = {}
StringArgumentType.__index = StringArgumentType
StringArgumentType.StringType = { -- why.
	SINGLE_WORD = "SINGLE_WORD" :: "SINGLE_WORD",
	QUOTABLE_PHRASE = "QUOTABLE_PHRASE" :: "QUOTABLE_PHRASE",
	GREEDY_PHRASE = "GREEDY_PHRASE" :: "GREEDY_PHRASE"
}

export type StringType = "SINGLE_WORD"
	| "QUOTABLE_PHRASE"
	| "GREEDY_PHRASE"

export type StringArgumentType = {
	stringType: StringType,
	parse: (self: StringArgumentType, input: string) -> (string, number)
}

function StringArgumentType.new(stringType: StringType): StringArgumentType
	return setmetatable({ stringType = stringType }, StringArgumentType) :: StringArgumentType
end

--[=[
	A string argument type.

	Gets the first word seperated by whitespace.
	Leading whitespaces to a word are accounted and ignored.
]=]
function StringArgumentType.word(): StringArgumentType
	return StringArgumentType.new(StringArgumentType.StringType.SINGLE_WORD)
end

--[=[
	A string argument type.
]=]
function StringArgumentType.string(): StringArgumentType
	return StringArgumentType.new(StringArgumentType.StringType.QUOTABLE_PHRASE)
end

--[=[
	A string argument type.

	Consumes the rest of the string.
]=]
function StringArgumentType.greedyString(): StringArgumentType
	return StringArgumentType.new(StringArgumentType.StringType.GREEDY_PHRASE)
end

--

--[=[
	Returns a string from an argument with the name of `name`.<p>
	Throws an error if the argument returns a non-string value.<p>
	This the preffered method for getting a string value from an argument,
	as directly calling `context:getArgument()` returns a value of type `any`
	which is not type safe-safe.
]=]
function StringArgumentType.getString<S>(context: CommandContext.CommandContext<S>, name: string): string
	local strArg = context:getArgument(name)
	if type(strArg) ~= "string" then
		error(`Argument '{name}' results in a value of type {typeof(strArg)}, expected string`)
	end
	return strArg
end

function StringArgumentType.parse(self: StringArgumentType, input: string): (string, number)
	if self.stringType == "GREEDY_PHRASE" then
		return input, input:len()
	elseif self.stringType == "SINGLE_WORD" then
		local word = input:match("^%s*(%S+)")
		if word then
			return word, #word
		end
		error("No single word found.")
	else
		local quoted = input:match('^%s*"(.-)"') or input:match("^%s*(%S+)")
		if quoted then
			return quoted, #quoted
		end
		error("No quoteable substrings found.")
	end
end

return StringArgumentType