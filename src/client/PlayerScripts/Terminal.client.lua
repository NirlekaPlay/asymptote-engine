--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local Base64 = require(ReplicatedStorage.shared.util.crypt.Base64)

local TerminalGui = ReplicatedStorage.shared.assets.gui.Terminal
local currentTerminalGui = TerminalGui:Clone()
currentTerminalGui.ResetOnSpawn = false
currentTerminalGui.Parent = Players.LocalPlayer.PlayerGui

local inputField = currentTerminalGui.Root.SafeArea.TextBox
inputField.Visible = false
inputField.MultiLine = false

local CLEAN_PATTERN = "[%c%s]+$"

local history: {string} = {}
local historyIndex = 0
local historyCount = 0

local function proccessInput(str: string): ()
	local command = str:gsub(CLEAN_PATTERN, "") -- Clean it first

	table.insert(history, command)
	historyCount += 1
	historyIndex = historyCount + 1

	if string.sub(command, 1, 1) == "/" then
		-- This is a command
		TypedRemotes.ServerboundPlayerSendCommand:FireServer(str)
	else
		-- A regular text
		TypedRemotes.ServerBoundClientForeignChatted:FireServer(Base64.encode(str))
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not inputField:IsFocused() then
		return
	end

	if input.KeyCode == Enum.KeyCode.Up then
		if historyIndex > 1 then
			historyIndex -= 1
			inputField.Text = history[historyIndex]
			-- Move cursor to the end of the line
			task.defer(function() inputField.CursorPosition = #inputField.Text + 1 end)
		end
		
	elseif input.KeyCode == Enum.KeyCode.Down then
		if historyIndex < #history then
			historyIndex += 1
			inputField.Text = history[historyIndex]
		else
			historyIndex = #history + 1
			inputField.Text = "" -- Clear if they go past the newest command
		end
	end
end)

ContextActionService:BindAction("ACTION_TERMINAL", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	inputField.Visible = not inputField.Visible
	if inputField.Visible then
		inputField:CaptureFocus()
	else
		inputField:ReleaseFocus()
	end

	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.T)

inputField.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		proccessInput(inputField.Text)
		task.wait() -- Prevents an additional space character
		inputField.Text = ""
		-- Click back into the box 
		-- so they can keep typing without clicking again
		task.defer(function()
			inputField:CaptureFocus()
		end)
	end
end)