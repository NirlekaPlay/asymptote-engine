--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local CommandsClientPacketListener = require(StarterPlayer.StarterPlayerScripts.client.modules.commands.CommandsClientPacketListener)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

-- Constants for styling (Minecraft values)
local LITERAL_STYLE = Color3.fromRGB(170, 170, 170)
local UNPARSED_STYLE = Color3.fromRGB(255, 85, 85)

local CommandSuggestions = {}
CommandSuggestions.__index = CommandSuggestions

export type CommandSuggestions = typeof(setmetatable({} :: {
	input: TextBox,
	currentParse: ParseResults.ParseResults<any>?,
	pendingSuggestions: CompletableFuture.CompletableFuture<Suggestions.Suggestions>?,
	keepSuggestions: boolean,
	commandsOnly: boolean,
	onlyShowIfCursorPastError: boolean,
}, CommandSuggestions))

function CommandSuggestions.new(textBox: TextBox): CommandSuggestions
	local self = setmetatable({
		input = textBox,
		currentParse = nil,
		pendingSuggestions = nil,
		keepSuggestions = false,
		commandsOnly = false,
		onlyShowIfCursorPastError = false,
	}, CommandSuggestions)
	
	return self
end

function CommandSuggestions:updateCommandInfo()
	local text = self.input.Text
	
	-- 1. Reset check: If text changed, the old parse is invalid
	if self.currentParse and self.currentParse.reader.string ~= text then
		self.currentParse = nil
	end

	if not self.keepSuggestions then
		-- In MC, this clears the gray "ghost" text
		-- self.input.PlaceholderText = "" 
		self.suggestions = nil
	end

	local reader = StringReader.fromString(text)
	local isCommand = reader:canRead() and reader:peek() == "/"
	if isCommand then
		reader:skip()
	end

	local shouldParse = self.commandsOnly or isCommand
	local cursorPosition = self.input.CursorPosition
	
	if shouldParse then
		local dispatcher = CommandsClientPacketListener.getDispatcher()
		
		-- 2. Parse the command if we don't have a cached result
		if not self.currentParse then
			-- Note: SharedSuggestionProvider in Luau is usually the LocalPlayer
			self.currentParse = dispatcher:parse(reader, "LocalPlayer")
		end

		-- 3. Determine if we should show suggestions based on error position
		local errorLimit = if self.onlyShowIfCursorPastError then reader:getCursorPos() else 1
		local adjustedCursor = if isCommand then cursorPosition - 1 else cursorPosition
		
		if cursorPosition >= errorLimit and (not self.suggestions or not self.keepSuggestions) then
			-- 4. Get suggestions (The "CompletableFuture" part)
			-- If your Luau port is synchronous, this is easy. 
			-- If it's async, you'd wrap this in a task.spawn
			local suggestionsPromise = dispatcher:_getCompletionSuggestions(self.currentParse, adjustedCursor)
			
			self.pendingSuggestions = suggestionsPromise
			
			suggestionsPromise:thenRun(function()
				if (self.pendingSuggestions :: typeof(({} :: CommandSuggestions).pendingSuggestions)):isDone() then
					self:updateUsageInfo()
				end
			end)
		end
	else
		-- Logic for non-command suggestions (chat names, etc.)
		-- This is where you'd call a custom provider
	end
end

function CommandSuggestions:updateUsageInfo()
	-- This is where the Minecraft code decides whether to:
	-- A) Show the suggestion box
	-- B) Show the "Usage: /tp <player>" hint
	-- C) Show a red syntax error
	
	if not self.pendingSuggestions then return end

	print(self.pendingSuggestions)
	--print(CommandsClientPacketListener.getDispatcher():getRoot())
	
	-- If suggestions are empty, MC checks for exceptions in the parse results
	--[[if #self.pendingSuggestions.list == 0 and self.currentParse then
		local exceptions = self.currentParse.exceptions
		-- Handle showing red error text here...
	end]]
	
	-- Trigger the actual UI pop-up
	self:showSuggestions(false)
end

function CommandSuggestions:showSuggestions(isTabPressed: boolean)
	if self.pendingSuggestions then
		-- Logic to create your UI frames for the suggestion list goes here
		-- This effectively populates the "SuggestionsList" inner class logic
	end
end

return CommandSuggestions