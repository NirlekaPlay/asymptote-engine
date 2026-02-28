--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local CommandsClientPacketListener = require(StarterPlayer.StarterPlayerScripts.client.modules.commands.CommandsClientPacketListener)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local Suggestion = require(ReplicatedStorage.shared.commands.suggestion.Suggestion)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

local BACKGROUND_COLOR = Color3.fromRGB(0, 0, 0)
local BACKGROUND_TRANSPARENCY = 0.2
local SUGGESTION_HEIGHT = 20

local REPEAT_DELAY = 0.4
local REPEAT_RATE = 0.08

--[=[
	@class CommandSuggestions
]=]
local CommandSuggestions = {}
CommandSuggestions.__index = CommandSuggestions

export type CommandSuggestions = typeof(setmetatable({} :: {
	input: TextBox,
	currentParse: ParseResults.ParseResults<any>?,
	pendingSuggestions: CompletableFuture.CompletableFuture<Suggestions.Suggestions>?,
	keepSuggestions: boolean,
	commandsOnly: boolean,
	onlyShowIfCursorPastError: boolean,
	selectedSuggestionIndex: number,
	currentSuggestions: {Suggestion.Suggestion},
	suggestions: Suggestions.Suggestions,
	isTabbing: boolean,
	originalText: string,
	--
	suggestionFrame: ScrollingFrame,
	--
	lastCycleTime: number,
	initialPressTime: number,
	isRepeating: boolean
}, CommandSuggestions))

function CommandSuggestions.new(textBox: TextBox): CommandSuggestions
	local self = setmetatable({
		input = textBox,
		currentParse = nil,
		pendingSuggestions = nil,
		keepSuggestions = false,
		commandsOnly = false,
		onlyShowIfCursorPastError = false,
		selectedSuggestionIndex = 0,
		isTabbing = false,
		originalText = "",
		currentSuggestions = {},
		--
		lastCycleTime = 0,
		initialPressTime = 0,
		isRepeating = false
	}, CommandSuggestions)

	-- The Container: Growing upwards
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "SuggestionContainer"
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
	frame.BorderSizePixel = 0
	frame.Visible = false
	-- Anchor at bottom-left so it expands UP
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.ScrollBarThickness = 4
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- Newest suggestions at bottom
	layout.Parent = frame

	-- TODO: This is hacky as shit
	frame.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Terminal")
	
	self.suggestionFrame = frame
	
	return self
end

function CommandSuggestions.isVisible(self: CommandSuggestions): boolean
	return self.suggestionFrame.Visible
end

function CommandSuggestions.onUserTyped(self: CommandSuggestions)
	self.isTabbing = false
	self:updateCommandInfo()
end

function CommandSuggestions.finalizeSelection(self: CommandSuggestions)
	self.suggestionFrame.Visible = false
	self.isTabbing = false
	self.currentSuggestions = {}
end

function CommandSuggestions.stopRepeat(self: CommandSuggestions)
	self.isRepeating = false
	self.lastCycleTime = 0
	self.initialPressTime = 0
end

function CommandSuggestions.updateAutoRepeat(self: CommandSuggestions, direction: number)
	local now = os.clock()
	
	if not self.isRepeating then
		self.isRepeating = true
		self.initialPressTime = now
		self.lastCycleTime = now
	else
		local timeSinceStart = now - self.initialPressTime
		local timeSinceLastTick = now - self.lastCycleTime

		if timeSinceStart >= REPEAT_DELAY then
			if timeSinceLastTick >= REPEAT_RATE then
				self.lastCycleTime = now
				self:cycleSelection(direction)
			end
		end
	end
end

function CommandSuggestions.updateCommandInfo(self: CommandSuggestions): ()
	local text = self.input.Text

	if self.currentParse and self.currentParse.reader.string ~= text then
		self.currentParse = nil
	end

	if not self.keepSuggestions then
		-- In Minecraft, this clears the gray ghost text
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

		if not self.currentParse then
			self.currentParse = dispatcher:parse(reader, {})
		end

		local errorLimit = if self.onlyShowIfCursorPastError then reader:getCursorPos() else 1
		local adjustedCursor = if isCommand then cursorPosition - 1 else cursorPosition
		
		if cursorPosition >= errorLimit and (not self.suggestions or not self.keepSuggestions) then
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
	end
end

function CommandSuggestions.updateUsageInfo(self: CommandSuggestions)
	if not self.pendingSuggestions then
		return
	end

	self:showSuggestions(false)
end

function CommandSuggestions.setSelection(self: CommandSuggestions, index: number)
	local count = #self.currentSuggestions
	if count == 0 then
		return
	end
	
	if index > count then index = 1 end
	if index < 1 then index = count end
	
	self.selectedSuggestionIndex = index
	
	local scrollFrame = self.suggestionFrame

	for _, label in scrollFrame:GetChildren() do
		if label:IsA("TextLabel") then
			if label.LayoutOrder == index then
				label.BackgroundTransparency = 0.2
			else
				label.BackgroundTransparency = 1
			end
		end
	end

	-- Calculate scroll position mathematically using index * item height
	local itemTop = (index - 1) * SUGGESTION_HEIGHT
	local itemBottom = itemTop + SUGGESTION_HEIGHT
	local scrollPos = scrollFrame.CanvasPosition.Y
	local frameHeight = scrollFrame.AbsoluteSize.Y

	if itemTop < scrollPos then
		scrollFrame.CanvasPosition = Vector2.new(0, itemTop)
	elseif itemBottom > (scrollPos + frameHeight) then
		scrollFrame.CanvasPosition = Vector2.new(0, itemBottom - frameHeight)
	end
end

function CommandSuggestions.applySelection(self: CommandSuggestions, destroy: boolean?)
	destroy = if destroy == nil then true else destroy

	local selected = self.currentSuggestions[self.selectedSuggestionIndex]
	if not selected then return end
	
	local text = self.input.Text
	local range = selected.range
	
	-- 1-based indexing for Lua string.sub
	local prefix = text:sub(1, range.startPos)
	local suffix = text:sub(range.endPos + 1)
	
	self.input.Text = prefix .. selected.text .. suffix
	self.input.CursorPosition = range.startPos + #selected.text + 1

	if destroy then
		self.suggestionFrame.Visible = false
		self.currentSuggestions = {}
	end
end

function CommandSuggestions.cycleSelection(self: CommandSuggestions, direction: number)
	local count = #self.currentSuggestions
	if count == 0 then return end

	-- 1. If this is the FIRST tab press, save what the user typed
	if not self.isTabbing then
		self.isTabbing = true
		self.originalText = self.input.Text
		self.selectedSuggestionIndex = 0 
	end

	-- 2. Increment/Decrement index
	local newIndex = self.selectedSuggestionIndex + direction
	
	-- Wrap around logic
	if newIndex > count then newIndex = 1 end
	if newIndex < 1 then newIndex = count end
	
	self.selectedSuggestionIndex = newIndex
	
	-- 3. Update UI highlighting
	self:setSelection(newIndex)
	
	-- 4. TEMPORARILY apply to TextBox (The Minecraft "Ghost" behavior)
	local selected = self.currentSuggestions[newIndex]
	local range = selected.range
	
	-- Use originalText so we don't build on top of previous suggestions
	local prefix = self.originalText:sub(1, range.startPos)
	local suffix = self.originalText:sub(range.endPos + 1)
	
	self.input.Text = prefix .. selected.text .. suffix
	self.input.CursorPosition = range.startPos + #selected.text + 1
end

function CommandSuggestions.showSuggestions(self: CommandSuggestions, isTabPressed: boolean)
	if self.pendingSuggestions then
		self:renderSuggestions(self.pendingSuggestions:join())
	end
end

function CommandSuggestions.renderSuggestions(self: CommandSuggestions, results: Suggestions.Suggestions): ()
	local suggestions = results.suggestions
	if next(suggestions) == nil then
		self.suggestionFrame.Visible = false
		return
	end

	-- We wrap this in a task because GetTextBoundsAsync yields
	task.spawn(function()
		local currentText = self.input.Text
		
		-- Calculate offset based on the START of the suggestion range
		-- This keeps the box steady while you type the word
		local textBeforeRange = currentText:sub(1, results.range.startPos)
		
		local params = Instance.new("GetTextBoundsParams")
		params.Text = textBeforeRange
		params.Font = self.input.FontFace
		params.Size = self.input.TextSize
		params.Width = 10000
		
		local success, bounds = pcall(function()
			return TextService:GetTextBoundsAsync(params)
		end)
		
		if not success or self.input.Text ~= currentText then
			return
		end

		-- Position relative to the TextBox's AbsolutePosition
		local xOffset = bounds.X
		local inputPos = self.input.AbsolutePosition
		
		-- Minecraft style: The box stays at the start of the word
		self.suggestionFrame.Position = UDim2.new(0, inputPos.X + xOffset, 0, inputPos.Y)
		-- AnchorPoint (0, 1) ensures it grows UP from the top of the box
		self.suggestionFrame.AnchorPoint = Vector2.new(0, 1) 
		
		local totalHeight = math.min(#suggestions, 10) * 20
		self.suggestionFrame.Size = UDim2.new(0, 150, 0, totalHeight)
		self.suggestionFrame.Visible = true

		-- Refill logic
		self.suggestionFrame:ClearAllChildren()
		local layout = Instance.new("UIListLayout")
		layout.Parent = self.suggestionFrame

		for i, suggestion in suggestions do
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 20)
			label.BackgroundTransparency = 1
			label.Text = " " .. suggestion.text
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.FontFace = self.input.FontFace
			label.TextSize = self.input.TextSize - 2
			label.LayoutOrder = i
			label.Parent = self.suggestionFrame
		end

		self.currentSuggestions = suggestions
		self.selectedSuggestionIndex = 0

		-- Fix scrolling frame reset
		self.suggestionFrame.CanvasPosition = Vector2.new(0, 0)
		self.suggestionFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	end)
end

return CommandSuggestions