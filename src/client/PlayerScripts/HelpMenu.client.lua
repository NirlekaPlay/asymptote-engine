--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local MouseManager = require(StarterPlayer.StarterPlayerScripts.client.modules.input.MouseManager)
local help_menu_en_us = require(ReplicatedStorage.shared.assets.lang.helpmenu["help-menu-en-us"])

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local HelpMenuGui = ReplicatedStorage.shared.assets.gui.Help

local HelpContent = help_menu_en_us

local MOUSE_OVERRIDE_ID = "HELP_MENU"

local BLUR_CC_NAME = "HelpMenuBlurCC"
local BLUR_SIZE = 25

local STD_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local STD_BG_COLOR = Color3.fromRGB(0, 0, 0)
local STD_BG_TRANSPARENCY = 1

local SELECTED_TEXT_COLOR = Color3.fromRGB(0, 0, 0)
local SELECTED_BG_COLOR = Color3.fromRGB(255, 255, 255)
local SELECTED_BG_TRANSPARENCY = 0

local ROOT_OFF_SCREEN_POS = UDim2.new(0.5, 0, -1, 0)
local ROOT_ON_SCREEN_POS = UDim2.new(0.5, 0, 0, 0)
local SHOW_TWEEN_DUR = 0.5
local TWEEN_INFO_IN = TweenInfo.new(
	SHOW_TWEEN_DUR,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

local currentSelection: TextButton? = nil

local function getScreenGui(): typeof(HelpMenuGui)
	local existing = PlayerGui:FindFirstChild(HelpMenuGui.Name)
	if not existing then
		local new = HelpMenuGui:Clone()
		new.Enabled = true
		new.Parent = PlayerGui
		return new
	end

	return existing :: any
end

local function getBlurCc(): BlurEffect
	local existing = workspace.CurrentCamera:FindFirstChild(BLUR_CC_NAME)
	if existing and existing:IsA("BlurEffect") then
		return existing
	end

	local blurcc = Instance.new("BlurEffect")
	blurcc.Size = 0
	blurcc.Enabled = true
	blurcc.Name = BLUR_CC_NAME
	blurcc.Parent = workspace.CurrentCamera

	return blurcc
end

local Root = getScreenGui().Root
local SafeArea = Root.SafeArea
local ChaptersFrame = SafeArea.Chapters
local PageFrame = SafeArea.Page

local ChapterTitleLabel = PageFrame.Chapter
local BodyTextLabel = PageFrame.Body
local ReferenceButton = ChaptersFrame.REF

-- Function to update the displayed content
local function updatePageContent(contentTable)
	if contentTable then
		ChapterTitleLabel.Text = contentTable.Title
		
		local rawText = contentTable.Body
		-- NOTE: Insane yap ahead:

		-- Clean up the raw string.
		-- We remove the leading/trailing whitespace introduced by the [=[ ]=] syntax,
		-- and then replace literal newlines combined with source code indentation with a single space.
		
		-- Trim leading whitespace/newlines at the start and end of the string
		-- The pattern (^%s*.*%S) ensures we capture the non-whitespace content.
		local trimmedText = rawText:match("^%s*(.*)") or ""
		
		-- Find lines that start with whitespace and replace the newline-whitespace sequence with a space.
		-- This flattens the code formatting into a single line.
		-- NOTE: We use [^\\] to ensure we do not touch the intentional "\n" sequences.
		local flattenedText = (trimmedText :: any):gsub("([^\\])[\r\n]+%s*", "%1 ")

		-- Replace the intentional literal "\n" sequence with a real newline character
		-- The previous steps ensure that only the intended "\n" remains for processing.
		BodyTextLabel.Text = flattenedText:gsub("\\n", "\n")

		-- Reset scroll position
		PageFrame.CanvasPosition = Vector2.new(0, 0)
	end
end

local function updateButtonAppearance(selectedButton: TextButton)
	-- Reset the previous selection's appearance
	if currentSelection then
		currentSelection.TextColor3 = STD_TEXT_COLOR
		currentSelection.BackgroundColor3 = STD_BG_COLOR
		currentSelection.BackgroundTransparency = STD_BG_TRANSPARENCY
		currentSelection.Interactable = true
	end

	-- Apply the selected appearance to the new button
	if selectedButton and selectedButton:IsA("TextButton") then
		selectedButton.TextColor3 = SELECTED_TEXT_COLOR
		selectedButton.BackgroundColor3 = SELECTED_BG_COLOR
		selectedButton.BackgroundTransparency = SELECTED_BG_TRANSPARENCY
		selectedButton.Interactable = false

		-- Update the current selection tracker
		currentSelection = selectedButton
	end
end

for index, chapterData in HelpContent do
	local newButton = ReferenceButton:Clone()
	newButton.Name = "Chapter" .. index
	newButton.Text = chapterData.ButtonText
	newButton.Visible = true
	newButton.Parent = ChaptersFrame

	newButton.MouseButton1Click:Connect(function()
		updatePageContent(chapterData)

		updateButtonAppearance(newButton)
	end)

	if index == 1 then
		updateButtonAppearance(newButton)
		updatePageContent(chapterData)
	end
end

ReferenceButton.Visible = false

--

local function setupRootFrame()
	Root.AnchorPoint = Vector2.new(0.5, 0)
	Root.Position = ROOT_OFF_SCREEN_POS
	Root.Visible = false
end

local isTweening = false
local isVisible = false

local function slideInMenu()
	isTweening = true
	if not Root.Visible then
		Root.Visible = true
	end

	local showTween = TweenService:Create(
		Root,
		TWEEN_INFO_IN,
		{Position = ROOT_ON_SCREEN_POS}
	)
	showTween:Play()

	TweenService:Create(
		getBlurCc(),
		TWEEN_INFO_IN,
		{ Size = BLUR_SIZE }
	):Play()

	showTween.Completed:Once(function()
		isTweening = false
	end)
end

local function slideOutMenu()
	isTweening = true
	
	local hideTween = TweenService:Create(
		Root,
		TWEEN_INFO_IN,
		{ Position = ROOT_OFF_SCREEN_POS }
	)
	hideTween:Play()

	TweenService:Create(
		getBlurCc(),
		TWEEN_INFO_IN,
		{ Size = 0 }
	):Play()
	
	hideTween.Completed:Once(function()
		Root.Visible = false
		isTweening = false
	end)
end

local function onInputPress(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
	if inputState ~= Enum.UserInputState.Begin or isTweening then
		return Enum.ContextActionResult.Pass
	end
	
	if not isVisible then
		MouseManager.addUnuseableMouseOverride(MOUSE_OVERRIDE_ID)
		slideInMenu()
		StarterGui:SetCore("ChatActive", false)
	else
		MouseManager.removeUnuseableMouseOverride(MOUSE_OVERRIDE_ID)
		slideOutMenu()
	end

	isVisible = not isVisible

	return Enum.ContextActionResult.Sink
end

setupRootFrame()
ContextActionService:BindAction("ACTION_HELP_MENU", onInputPress, false, Enum.KeyCode.H)