--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local SharedSuggestionProvider = require(ReplicatedStorage.shared.commands.asymptote.suggestion.SharedSuggestionProvider)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	@class EntityArgument
]=]
local EntityArgument = {}
EntityArgument.__index = EntityArgument

export type EntityArgument = ArgumentType.ArgumentType<any> & {}

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandContext<S> = CommandContext.CommandContext<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

function EntityArgument.entities(): EntityArgument
	return setmetatable({}, EntityArgument) :: EntityArgument
end

function EntityArgument.getEntities(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, name: string): {Instance}
	local parsedEntityArg = context:getArgument(name)
	local source = context:getSource()
	return EntitySelectorParser.resolvePlayerSelector(parsedEntityArg, source:getPlayerOrThrow()) :: { Instance }
end

function EntityArgument.parse(self: EntityArgument, input: string): (any, number)
	local result, consumed = EntitySelectorParser.parse(self, input)
	return result, consumed
end

local SELECTOR_LETTERS = {
	a = true,
	e = true,
	m = true,
	p = true,
	r = true,
	s = true
}

local PARAMETERS = {
	"distance",
	"name",
	"type",
	"alive",
	"limit"
}
table.sort(PARAMETERS)

local PARAMETER_VALUES = {
	alive = { "true", "false" },
	type  = { "player", "npc" },
}

function EntityArgument.listSuggestions<S>(self: EntityArgument, context: CommandContext<S>, builder: SuggestionsBuilder): CompletableFuture<Suggestions>
	if not SharedSuggestionProvider.isInstance(context:getSource()) then
		return Suggestions.empty()
	else
		local provider = SharedSuggestionProvider.getInstance(context:getSource())
		local playerList = provider:getOnlinePlayers()
		table.sort(playerList, function(a: any, b: any)
			return a.Name < b.Name
		end)

		local reader = StringReader.fromString(builder:getRemainingLowerCase())
		reader:skipWhitespace()

		local firstChar = reader:read()
		local isSelector = firstChar == "@"

		if not isSelector then
			builder:suggest("@a")
			builder:suggest("@e")
			builder:suggest("@m")
			builder:suggest("@p")
			builder:suggest("@r")
			builder:suggest("@s")
			for _, player in playerList do
				builder:suggest(player.Name)
			end
			return builder:buildFuture()
		end

		local selectorChar = reader:read()
		local isSelectorComplete = SELECTOR_LETTERS[selectorChar] == true

		if not isSelectorComplete then
			for letter in SELECTOR_LETTERS do
				builder:suggest("@" .. letter)
			end
			return builder:buildFuture()
		end

		reader:skipWhitespace()

		local nextChar = reader:peek()
		if nextChar ~= "[" then
			builder:suggest("[")
			return builder:buildFuture()
		end

		reader:read()
		reader:skipWhitespace()

		if not reader:canRead() then
			for _, paramName in PARAMETERS do
				builder:suggest(paramName .. "=")
			end
			return builder:buildFuture()
		end

		-- Parse through any already-entered params to find where we are
		-- Keep reading "param=value," segments until we reach the cursor
		while reader:canRead() do
			local next = reader:peek()

			if next == "]" then
				-- Cursor is after closing bracket, nothing to suggest
				return builder:buildFuture()
			end

			-- Check if we're at a position to suggest a param name
			-- (either right after "[" or after a ",")
			local remaining = reader:getRemaining()
			local hasEquals = remaining:find("=")

			if not hasEquals then
				-- Cursor is mid-param-name, suggest all params
				for _, paramName in PARAMETERS do
					builder:suggest(paramName .. "=")
				end
				return builder:buildFuture()
			end

			-- Capture the param name before consuming past "="
			local paramName = remaining:match("^([^=]+)=")

			-- Skip past "param="
			while reader:canRead() and reader:peek() ~= "=" do
				reader:read()
			end
			if reader:canRead() then
				reader:read() -- consume equal sign
			end

			if not reader:canRead() then
				-- Cursor is right after "=", suggest values
				local values = PARAMETER_VALUES[paramName]
				if values then
					for _, v in values do
						builder:suggest(v)
						builder:suggest("!" .. v)
					end
				end
				return builder:buildFuture()
			end

			-- Theres an "=", so a param name is already entered; skip past "param=value"
			-- Read until "," or "]"
			while reader:canRead() and reader:peek() ~= "," and reader:peek() ~= "]" do
				reader:read()
			end

			if not reader:canRead() then
				builder:suggest(",")
				builder:suggest("]")
				return builder:buildFuture()
			end

			if reader:peek() == "," then
				reader:read()
				reader:skipWhitespace()
				-- Loop again to suggest next param
			elseif reader:peek() == "]" then
				return builder:buildFuture()
			end
		end

		for _, paramName in PARAMETERS do
			builder:suggest(paramName .. "=")
		end

		return builder:buildFuture()
	end
end

return EntityArgument