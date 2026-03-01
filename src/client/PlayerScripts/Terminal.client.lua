--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local CommandSuggestions = require(StarterPlayer.StarterPlayerScripts.client.modules.commands.CommandSuggestions)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local Base64 = require(ReplicatedStorage.shared.util.crypt.Base64)
local UString = require(ReplicatedStorage.shared.util.string.UString)

local localPlayer = Players.LocalPlayer

local TerminalGui = ReplicatedStorage.shared.assets.gui.Terminal
local currentTerminalGui = TerminalGui:Clone()
currentTerminalGui.ResetOnSpawn = false
currentTerminalGui.Parent = Players.LocalPlayer.PlayerGui

local inputField = currentTerminalGui.Root.SafeArea.TextBox
inputField.Visible = false
inputField.MultiLine = false

local commandHistoryFrame = currentTerminalGui.Root.SafeArea.CommandHistory
local scrollingFrame = commandHistoryFrame.ScrollingFrame
local scrollingFrameUiListLayout = scrollingFrame.UIListLayout
local commandHistoryEntryTextRef = scrollingFrame.REF
commandHistoryFrame.Visible = false
commandHistoryEntryTextRef.Visible = false
commandHistoryEntryTextRef.RichText = true

local CLEAN_PATTERN = "[%c%s]+$"

local history: {string} = {}
local historyIndex = 0
local historyCount = 0

local isTerminalVisible = false
local commandSuggestions = CommandSuggestions.new(inputField)

local function setTerminalVisibility(visible: boolean): ()
	isTerminalVisible = visible

	inputField.Visible = isTerminalVisible
	commandHistoryFrame.Visible = isTerminalVisible
end

local function addEntry(by: string, content: string): ()
	local formerParent = commandHistoryEntryTextRef.Parent
	local newEntry = commandHistoryEntryTextRef:Clone()
	newEntry.Parent = formerParent

	local finalStr
	if UString.isBlank(by) then
		finalStr = content
	else
		finalStr = `<b>&lt;{by}&gt;</b> {content}`
	end

	newEntry.RichText = true
	newEntry.Text = finalStr
	newEntry.TextWrapped = true
	newEntry.Visible = true

	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, scrollingFrameUiListLayout.AbsoluteContentSize.Y)

	-- Auto-scroll to the bottom
	scrollingFrame.CanvasPosition = Vector2.new(0, scrollingFrame.AbsoluteCanvasSize.Y)
end

local function clearEntries(): ()
	for _, child in scrollingFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function proccessInput(str: string): ()
	local command = str:gsub(CLEAN_PATTERN, "") -- Clean it first

	table.insert(history, command)
	historyCount += 1
	historyIndex = historyCount + 1

	if string.sub(command, 1, 1) == "/" then
		-- This is a command
		TypedRemotes.ServerboundPlayerSendCommand:FireServer(str)
		TypedRemotes.ServerBoundClientForeignChatted:FireServer(Base64.encode(str))
		addEntry(localPlayer.Name, str)
	else
		-- A regular text
		TypedRemotes.ServerBoundClientForeignChatted:FireServer(Base64.encode(str))
		addEntry(localPlayer.Name, str)
	end
end

local heldDirection = 0 -- 0 = None, 1 = Tab/Down, -1 = Up

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isTerminalVisible then
		if UserInputService:IsKeyDown(Enum.KeyCode.F3) and UserInputService:IsKeyDown(Enum.KeyCode.D) then
			clearEntries()
		end
	end

	if not inputField:IsFocused() then
		return
	end
	
	local suggestionsActive = commandSuggestions:isVisible() and next(commandSuggestions.currentSuggestions) ~= nil

	if input.KeyCode == Enum.KeyCode.Tab then
		if suggestionsActive then
			heldDirection = 1
			commandSuggestions:cycleSelection(1)
			
			task.defer(function()
				inputField:CaptureFocus()
				inputField.CursorPosition = #inputField.Text + 1
			end)
		end
	elseif input.KeyCode == Enum.KeyCode.Up then
		if suggestionsActive then
			heldDirection = -1
			commandSuggestions:cycleSelection(-1)
		else
			-- Original history logic
			if historyIndex > 1 then
				historyIndex -= 1
				inputField.Text = history[historyIndex]
				task.defer(function() inputField.CursorPosition = #inputField.Text + 1 end)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Down then
		if suggestionsActive then
			heldDirection = 1
			commandSuggestions:cycleSelection(1)
		else
			-- Original history logic
			if historyIndex < #history then
				historyIndex += 1
				inputField.Text = history[historyIndex]
			else
				historyIndex = #history + 1
				inputField.Text = ""
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Return then
		if suggestionsActive then
			commandSuggestions:finalizeSelection()
		end
	elseif input.KeyCode == Enum.KeyCode.Space then
		commandSuggestions.isTabbing = false
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Up then
		heldDirection = 0
		commandSuggestions:stopRepeat()
	end
end)

RunService.PreRender:Connect(function()
	if heldDirection ~= 0 and inputField:IsFocused() then
		commandSuggestions:updateAutoRepeat(heldDirection)
	end
end)

ContextActionService:BindAction("ACTION_TERMINAL", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	setTerminalVisibility(not isTerminalVisible)
	if isTerminalVisible then
		inputField:CaptureFocus()
	else
		inputField:ReleaseFocus()
	end

	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.T)

inputField.Focused:Connect(function()
	if inputField.Text ~= "" then
		commandSuggestions.suggestionFrame.Visible = true
	end
end)

inputField.FocusLost:Connect(function(enterPressed)
	commandSuggestions.isTabbing = false
	commandSuggestions.suggestionFrame.Visible = false
	if enterPressed then
		if UString.isBlank(inputField.Text) then
			task.defer(function()
				inputField:CaptureFocus()
			end)
			return
		end
		proccessInput(inputField.Text)
		task.wait() -- Prevents an additional space character
		inputField.Text = ""

		-- Click back into the box if shift is held
		-- so they can keep typing without clicking again
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			task.defer(function()
				inputField:CaptureFocus()
			end)
		else
			inputField:ReleaseFocus()
			setTerminalVisibility(false)
		end
	end
end)

local lastText = ""
inputField:GetPropertyChangedSignal("Text"):Connect(function()
	local text = inputField.Text
	
	local cleaned = text:gsub("\t", "")
	if cleaned ~= text then
		inputField.Text = cleaned
		return
	end

	if cleaned ~= lastText then
		lastText = cleaned

		if commandSuggestions.suppressNextTextChange then
			commandSuggestions.suppressNextTextChange = false
			return
		end

		commandSuggestions:updateCommandInfo()

		if cleaned == "" then
			-- Disable suggestions mode so the user can cycle though history like normal
			commandSuggestions.suggestionFrame.Visible = false
		end
	end
end)

--

TypedRemotes.ClientBoundChatMessage.OnClientEvent:Connect(function(payload)
	addEntry("", MutableTextComponent.deserialize(payload.content):buildRichTextMarkupString())
end)

TypedRemotes.ClientBoundForeignChatMessage.OnClientEvent:Connect(function(player, content)
	addEntry(player.Name, Base64.decode(content))
end)
