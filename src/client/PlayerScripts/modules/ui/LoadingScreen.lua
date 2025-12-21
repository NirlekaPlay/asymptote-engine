--!strict

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local QuoteOfTheDay = require(ReplicatedStorage.shared.quotes.QuoteOfTheDay)
local QuoteOfTheDayList = require(ReplicatedStorage.shared.quotes.QuoteOfTheDayList)
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.core.CoreCall)
local UITextShadow = require(script.Parent.UITextShadow)

local DEBUG_MODE_ATTRIBUTE_NAME = "QuoteOfTheDayDebugMode"
local DEBUG_MODE = StarterGui:GetAttribute(DEBUG_MODE_ATTRIBUTE_NAME)
local DEBUG_QUOTE_OF_THE_DAY_INDEX_ATTRIBUTE_NAME = "QuoteOfTheDayIndex"
local DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME = "ShowQuoteOfTheDayUi"
local DEBUG_BACKGROUND_INDEX_ATTRIBUTE_NAME = "BakckgroundIndex"

local LOADING_SCREEN_SCREEN_GUI_NAME = "LoadingScreen"
local LOADING_SCREEN_BACKGROUND_COLOR = Color3.new(0.090196, 0.090196, 0.090196)
local LOADING_SCREEN_BACKGROUND_IDS = {
	{ name = "Hub Room", id = 93100734007160 },
	{ name = "The Founder's Eye", id = 119595682823582 },
	{ name = "She's Dead", id = 129935296812180 },
	{ name = "A Tester's Favorite Item", id = 112033098640768 },
	{ name = "Mr. Fox's Fiery Rehearsal Session", id = 94507925788952},
	{ name = "Darkness and Light", id = 98157055540963 },
	{ name = "Falling Stairs of God", id = 78883576372525 }
}
local TWEEN_INFO_FADE = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local lastArrivedBackgroundId: number? = nil
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentLoadingScreenGui: ScreenGui

task.spawn(function()
	local t = table.create(#LOADING_SCREEN_BACKGROUND_IDS, true) :: {string}
	for i, v in LOADING_SCREEN_BACKGROUND_IDS do
		t[i] = `rbxassetid://{v}`
	end
	ContentProvider:PreloadAsync(t)
end)

--[=[
	@class LoadingScreen

	Manages the UI you see when teleporting accross places.
]=]
local LoadingScreen = {}

function LoadingScreen.revert(): ()
	CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.All, true)

	local tweens: { Tween } = {}
	local trackingTween: Tween
	for _, guiObject in ipairs((currentLoadingScreenGui:FindFirstChild("Frame") :: Frame):GetChildren()) do
		if guiObject:IsA("TextLabel") then
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { TextTransparency = 1 }
			)
			table.insert(tweens, newTween)

			if not trackingTween then
				trackingTween = newTween
			end
		elseif guiObject:IsA("ImageLabel") then
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { ImageTransparency = 1 }
			)
			local newTween1 = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { BackgroundTransparency = 1 }
			)
			table.insert(tweens, newTween)
			table.insert(tweens, newTween1)

			if not trackingTween then
				trackingTween = newTween
			end
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end
end

function LoadingScreen.onTeleporting(delay: number, teleportCallback: () -> ())
	if DEBUG_MODE then
		warn("Debug mode for Quote of the Days is enabled. \n Cannot proceed with normal teleport loading screen operations.")
		return
	end

	if not currentLoadingScreenGui then
		currentLoadingScreenGui = LoadingScreen.createLoadingScreenGui()
	end

	CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.All, false)

	local tweens: { Tween } = {}
	local trackingTween: Tween
	for _, guiObject in ipairs((currentLoadingScreenGui:FindFirstChild("Frame") :: Frame):GetChildren()) do
		if guiObject:IsA("TextLabel") then
			guiObject.TextTransparency = 1
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { TextTransparency = 0 }
			)
			table.insert(tweens, newTween)

			if not trackingTween then
				trackingTween = newTween
			end
		elseif guiObject:IsA("ImageLabel") then
			guiObject.ImageTransparency = 1
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { ImageTransparency = 0 }
			)
			local newTween1 = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { BackgroundTransparency = 0 }
			)
			table.insert(tweens, newTween)
			table.insert(tweens, newTween1)

			if not trackingTween then
				trackingTween = newTween
			end
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	if trackingTween then
		trackingTween.Completed:Wait()
	end

	task.wait(delay)

	TeleportService:SetTeleportGui(currentLoadingScreenGui :: any)

	teleportCallback()
end

function LoadingScreen.createLoadingScreenGui(): ScreenGui
	local quoteOfTheDay = QuoteOfTheDay.getQuoteOfTheDay()

	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.DisplayOrder = 99999 -- make sure its on top of everything
	newScreenGui.Name = LOADING_SCREEN_SCREEN_GUI_NAME

	local rootFrame = Instance.new("Frame")
	rootFrame.BackgroundTransparency = 1
	rootFrame.Size = UDim2.fromScale(1, 1)
	rootFrame.Parent = newScreenGui

	local backgroundImageLabel = Instance.new("ImageLabel")
	backgroundImageLabel.Name = "Background"
	backgroundImageLabel.Size = UDim2.fromScale(1, 1)
	backgroundImageLabel.ScaleType = Enum.ScaleType.Crop
	backgroundImageLabel.ZIndex = 0
	backgroundImageLabel.BackgroundTransparency = 0
	backgroundImageLabel.BackgroundColor3 = LOADING_SCREEN_BACKGROUND_COLOR
	backgroundImageLabel.ImageContent = Content.fromAssetId(LoadingScreen.selectBackgroundId())
	backgroundImageLabel.Parent = rootFrame

	local quoteHeaderText = Instance.new("TextLabel")
	quoteHeaderText.Name = "Header"
	quoteHeaderText.BackgroundTransparency = 1
	quoteHeaderText.TextColor3 = Color3.new(1, 1, 1)
	quoteHeaderText.FontFace = Font.fromName("Zekton")
	quoteHeaderText.TextScaled = true
	quoteHeaderText.Position = UDim2.fromScale(0.05, 0.718)
	quoteHeaderText.Size = UDim2.fromScale(0.469,0.051)
	quoteHeaderText.TextXAlignment = Enum.TextXAlignment.Left
	quoteHeaderText.Text = "Quote of The Day:"
	quoteHeaderText.ZIndex = 3
	quoteHeaderText.Parent = rootFrame

	UITextShadow.createTextShadow(quoteHeaderText, nil, 1.5, nil, 0.5)

	local quoteMessageText = Instance.new("TextLabel")
	quoteMessageText.Name = "Message"
	quoteMessageText.BackgroundTransparency = 1
	quoteMessageText.TextColor3 = Color3.new(1, 1, 1)
	quoteMessageText.FontFace = Font.fromName("Zekton", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	quoteMessageText.TextScaled = true
	quoteMessageText.Size = UDim2.fromScale(0.811, 0.061)
	quoteMessageText.Position = UDim2.fromScale(0.052, 0.766)
	quoteMessageText.TextXAlignment = Enum.TextXAlignment.Left
	quoteMessageText.Text = quoteOfTheDay.message
	quoteMessageText.ZIndex = 3
	quoteMessageText.Parent = rootFrame

	UITextShadow.createTextShadow(quoteMessageText, nil, 1.5, nil, 0.5)

	local quoteAuthorText = Instance.new("TextLabel")
	quoteAuthorText.Name = "Author"
	quoteAuthorText.BackgroundTransparency = 1
	quoteAuthorText.TextColor3 = Color3.new(1, 1, 1)
	quoteAuthorText.FontFace = Font.fromName("Zekton")
	quoteAuthorText.TextScaled = true
	quoteAuthorText.Size = UDim2.fromScale(0.44, 0.039)
	quoteAuthorText.Position = UDim2.fromScale(0.079, 0.827)
	quoteAuthorText.AutomaticSize = Enum.AutomaticSize.X
	quoteAuthorText.TextXAlignment = Enum.TextXAlignment.Left
	quoteAuthorText.Text = quoteOfTheDay.author
	quoteAuthorText.ZIndex = 3
	quoteAuthorText.Parent = rootFrame

	UITextShadow.createTextShadow(quoteAuthorText, nil, 1.5, nil, 0.5)

	newScreenGui.Enabled = true
	newScreenGui.Parent = playerGui

	return newScreenGui
end

function LoadingScreen.updateQuoteOfTheDay(quote: QuoteOfTheDayList.Quote): ()
	if not currentLoadingScreenGui then
		warn("Attempt to update the Quote of the Day loading screen UI: UI is not created yet.")
		return
	end

	local messageTextLabel = currentLoadingScreenGui.Frame.Message :: TextLabel
	local messageTextLabelShadow = currentLoadingScreenGui.Frame.Message_Shadow :: TextLabel
	local authorTextLabel = currentLoadingScreenGui.Frame.Author :: TextLabel
	local authorTextLabelShadow = currentLoadingScreenGui.Frame.Author_Shadow :: TextLabel

	messageTextLabel.Text = quote.message
	messageTextLabelShadow.Text = quote.message
	authorTextLabel.Text = quote.author
	authorTextLabelShadow.Text = quote.author
end

function LoadingScreen.updateBackground(background: { name: string, id: number }): ()
	if not currentLoadingScreenGui then
		warn("Attempt to update the background of the loading screen UI: UI is not created yet.")
		return
	end

	local backgroundImageLabel = currentLoadingScreenGui.Frame.Background
	backgroundImageLabel.ImageContent = Content.fromAssetId(background.id)
	print(`Updated background to: '{background.name}'`)
end

function LoadingScreen.setLastArrivedBackgroundId(id: number): ()
	lastArrivedBackgroundId = id
end

function LoadingScreen.selectBackgroundId(): number
	if #LOADING_SCREEN_BACKGROUND_IDS == 1 then
		return LOADING_SCREEN_BACKGROUND_IDS[1].id
	end

	local random = Random.new(tick())
	local index: number
	local background: { name: string, id: number }
	repeat
		index = random:NextInteger(1, #LOADING_SCREEN_BACKGROUND_IDS)
		background = LOADING_SCREEN_BACKGROUND_IDS[index]
	until not lastArrivedBackgroundId or background.id ~= lastArrivedBackgroundId

	return background.id
end

--

function LoadingScreen.debugGetQuoteFromSetIndex(): QuoteOfTheDayList.Quote?
	local index = StarterGui:GetAttribute(DEBUG_QUOTE_OF_THE_DAY_INDEX_ATTRIBUTE_NAME) :: number
	local quote = QuoteOfTheDay.getQuoteOfTheDayByIndex(index)
	if not quote then
		warn(`'{index}' index for quote is not valid or doesn't exist.`)
		return nil
	end

	return quote
end

function LoadingScreen.debugGetBackgroundFromSetIndex(): { name: string, id: number }?
	local index = StarterGui:GetAttribute(DEBUG_BACKGROUND_INDEX_ATTRIBUTE_NAME) :: number
	local background = LOADING_SCREEN_BACKGROUND_IDS[index]
	if not background then
		warn(`'{index}' index for background is not valid or doesn't exist.`)
		return nil
	end

	return background
end

if DEBUG_MODE then
	warn("Debug mode for Loading Screen Quote of the Days and backgrounds has been enabled!")
	warn("You can edit the 'QuoteOfTheDayIndex' set in StarterGui\n to see how will your Quote of the Days look!")
	print("Total amount of quotes in the list is:", #QuoteOfTheDayList)
	print("Total amount of backgrounds is:", #LOADING_SCREEN_BACKGROUND_IDS)

	local showUi = false
	StarterGui:SetAttribute(DEBUG_MODE_ATTRIBUTE_NAME, nil)
	StarterGui:SetAttribute(DEBUG_QUOTE_OF_THE_DAY_INDEX_ATTRIBUTE_NAME, 1)
	StarterGui:SetAttribute(DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME, showUi)
	StarterGui:SetAttribute(DEBUG_BACKGROUND_INDEX_ATTRIBUTE_NAME, 1)

	StarterGui:GetAttributeChangedSignal(DEBUG_QUOTE_OF_THE_DAY_INDEX_ATTRIBUTE_NAME):Connect(function()
		if not showUi then
			print(`Cannot update LoadingScreen quote: {DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME} attribute is disabled.`)
			return
		end

		local quote = LoadingScreen.debugGetQuoteFromSetIndex()
		if quote then
			LoadingScreen.updateQuoteOfTheDay(quote)
		end
	end)

	StarterGui:GetAttributeChangedSignal(DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME):Connect(function()
		showUi = StarterGui:GetAttribute(DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME)
		if (showUi and not currentLoadingScreenGui) then
			currentLoadingScreenGui = LoadingScreen.createLoadingScreenGui()
			local quote = LoadingScreen.debugGetQuoteFromSetIndex()
			if quote then
				LoadingScreen.updateQuoteOfTheDay(quote)
			end
		elseif not showUi and currentLoadingScreenGui then
			currentLoadingScreenGui:Destroy()
			currentLoadingScreenGui = nil
		end
	end)

	StarterGui:GetAttributeChangedSignal(DEBUG_BACKGROUND_INDEX_ATTRIBUTE_NAME):Connect(function()
		if not showUi then
			print(`Cannot update LoadingScreen background: {DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME} attribute is disabled.`)
			return
		end

		local background = LoadingScreen.debugGetBackgroundFromSetIndex()
		if background then
			LoadingScreen.updateBackground(background)
		end
	end)
end

return LoadingScreen