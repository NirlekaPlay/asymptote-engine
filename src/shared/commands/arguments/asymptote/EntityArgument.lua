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
	local source = context:getSource()
	if not SharedSuggestionProvider.isInstance(source) then
		return Suggestions.empty()
	end

	local provider = SharedSuggestionProvider.getInstance(source)
	local input = builder:getInput()
	local start = builder:getStart()
	local reader = StringReader.fromString(input)
	reader:setCursorPos(start)

	local currentSuggestionProvider = function(b: SuggestionsBuilder)
		b:suggest("@p")
		b:suggest("@a")
		b:suggest("@r")
		b:suggest("@s")
		b:suggest("@e")
		for _, player in provider:getOnlinePlayers() do
			b:suggest(player.Name)
		end
	end

	local function parse()
		if not reader:canRead() then return end

		if reader:peek() == "@" then
			reader:skip()
			
			currentSuggestionProvider = function(b: SuggestionsBuilder)
				local sub = b:createOffset(b:getStart() - 1)
				sub:suggest("@p")
				sub:suggest("@a")
				sub:suggest("@r")
				sub:suggest("@s")
				sub:suggest("@e")
				b:add(sub)
			end

			if not reader:canRead() then return end
			reader:read() -- consume selector char
			
			reader:skipWhitespace()
			currentSuggestionProvider = function(b: SuggestionsBuilder)
				b:suggest("[")
			end

			if reader:canRead() and reader:peek() == "[" then
				reader:skip() -- consume [
				
				-- IMMEDIATELY set provider for keys after consuming [
				currentSuggestionProvider = function(b: SuggestionsBuilder)
					for _, paramName in PARAMETERS do
						b:suggest(paramName .. "=")
					end
					b:suggest("]")
				end

				while reader:canRead() do
					reader:skipWhitespace()
					
					local keyStart = reader:getCursorPos()
					while reader:canRead() and reader:peek() ~= "=" and reader:peek() ~= "," and reader:peek() ~= "]" do
						reader:read()
					end
					local key = input:sub(keyStart + 1, reader:getCursorPos())

					if not reader:canRead() then return end
					
					if reader:peek() == "]" then
						reader:skip()
						currentSuggestionProvider = function(b: SuggestionsBuilder) end
						return
					end

					if reader:peek() == "=" then
						reader:skip() -- consume =
						
						currentSuggestionProvider = function(b: SuggestionsBuilder)
							local values = PARAMETER_VALUES[key]
							if values then
								for _, v in values do
									b:suggest(v)
									b:suggest("!" .. v)
								end
							end
						end

						while reader:canRead() and reader:peek() ~= "," and reader:peek() ~= "]" do
							reader:read()
						end
						
						if not reader:canRead() then return end
					end

					if reader:peek() == "," then
						reader:skip()
						-- IMMEDIATELY set provider for next key
						currentSuggestionProvider = function(b: SuggestionsBuilder)
							for _, paramName in PARAMETERS do
								b:suggest(paramName .. "=")
							end
						end
					elseif reader:peek() == "]" then
						reader:skip()
						currentSuggestionProvider = function(b: SuggestionsBuilder) end
						return
					end
				end
			end
		else
			local nameStart = reader:getCursorPos()
			reader:readString()
			currentSuggestionProvider = function(b: SuggestionsBuilder)
				local sub = b:createOffset(nameStart)
				for _, player in provider:getOnlinePlayers() do
					sub:suggest(player.Name)
				end
				b:add(sub)
			end
		end
	end

	pcall(parse)

	local finalBuilder = builder:createOffset(reader:getCursorPos())
	currentSuggestionProvider(finalBuilder)
	return finalBuilder:buildFuture()
end

return EntityArgument