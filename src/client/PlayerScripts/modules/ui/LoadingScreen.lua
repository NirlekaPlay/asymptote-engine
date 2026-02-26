--!strict

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local UIAutoScaledText = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.components.UIAutoScaledText)
local QuoteOfTheDay = require(ReplicatedStorage.shared.quotes.QuoteOfTheDay)
local QuoteOfTheDayList = require(ReplicatedStorage.shared.quotes.QuoteOfTheDayList)
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)

local DEBUG_MODE_ATTRIBUTE_NAME = "QuoteOfTheDayDebugMode"
local DEBUG_MODE = StarterGui:GetAttribute(DEBUG_MODE_ATTRIBUTE_NAME)
local DEBUG_QUOTE_OF_THE_DAY_INDEX_ATTRIBUTE_NAME = "QuoteOfTheDayIndex"
local DEBUG_QUOTE_OF_THE_DAY_UI_ENABLED_ATTRIBUTE_NAME = "ShowQuoteOfTheDayUi"
local DEBUG_BACKGROUND_INDEX_ATTRIBUTE_NAME = "BakckgroundIndex"

local LOADING_SCREEN_BACKGROUND_IDS = {
	{ name = "Hub Room", id = 93100734007160 },
	{ name = "The Founder's Eye", id = 119595682823582 },
	{ name = "She's Dead", id = 129935296812180 },
	{ name = "A Tester's Favorite Item", id = 112033098640768 },
	{ name = "Mr. Fox's Fiery Rehearsal Session", id = 94507925788952},
	{ name = "Darkness and Light", id = 98157055540963 },
	{ name = "Falling Stairs of God", id = 78883576372525 },
	{ name = "Administration Building", id = 137772869105675 }
}
local TWEEN_INFO_FADE = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local loadingScreenGui = ReplicatedStorage.shared.assets.gui.LoadingScreen
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
	for _, guiObject in currentLoadingScreenGui:GetChildren() do
		if guiObject:IsA("TextLabel") then
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { TextTransparency = 1 }
			)
			table.insert(tweens, newTween)
		elseif guiObject:IsA("ImageLabel") then
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { ImageTransparency = 1 }
			)
			local newTween1 = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { BackgroundTransparency = 1 }
			)
			table.insert(tweens, newTween)
			table.insert(tweens, newTween1)
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

	for _, guiObject in currentLoadingScreenGui:GetChildren() do
		local targetProperties = {}

		if guiObject:IsA("TextLabel") then
			targetProperties.TextTransparency = guiObject.TextTransparency
			guiObject.TextTransparency = 1
		elseif guiObject:IsA("ImageLabel") then
			targetProperties.ImageTransparency = guiObject.ImageTransparency
			targetProperties.BackgroundTransparency = guiObject.BackgroundTransparency
			guiObject.ImageTransparency = 1
			guiObject.BackgroundTransparency = 1
		elseif guiObject:IsA("Frame") then
			targetProperties.BackgroundTransparency = guiObject.BackgroundTransparency
			guiObject.BackgroundTransparency = 1
		end

		if next(targetProperties) then
			local newTween = TweenService:Create(guiObject, TWEEN_INFO_FADE, targetProperties)
			table.insert(tweens, newTween)
		end
	end

	for _, tween in tweens do
		tween:Play()
	end

	task.wait(0.5 + delay)

	TeleportService:SetTeleportGui(currentLoadingScreenGui :: any)

	teleportCallback()
end

function LoadingScreen.createLoadingScreenGui(): typeof(loadingScreenGui)
	local quoteOfTheDay = QuoteOfTheDay.getQuoteOfTheDay()
	local newScreenGui = loadingScreenGui:Clone()

	local authorText = UIAutoScaledText.fromTextLabel(newScreenGui.MainFrame.Author, 1080, newScreenGui.MainFrame.Author.TextSize)
	local quoteText = UIAutoScaledText.fromTextLabel(newScreenGui.MainFrame.Quote, 1080, newScreenGui.MainFrame.Author.TextSize)
	UIAutoScaledText.fromTextLabel(newScreenGui.MainFrame.Title, 1080, newScreenGui.MainFrame.Author.TextSize)
	local background = newScreenGui.Background

	authorText.Text = quoteOfTheDay.author
	quoteText.Text = quoteOfTheDay.message
	background.ImageContent = Content.fromAssetId(LoadingScreen.selectBackgroundId())

	newScreenGui.Parent = playerGui

	return newScreenGui
end

function LoadingScreen.updateQuoteOfTheDay(quote: QuoteOfTheDayList.Quote): ()
	if not currentLoadingScreenGui then
		warn("Attempt to update the Quote of the Day loading screen UI: UI is not created yet.")
		return
	end

	local messageTextLabel = currentLoadingScreenGui.MainFrame.Quote
	local authorTextLabel = currentLoadingScreenGui.MainFrame.Author

	messageTextLabel.Text = quote.message
	authorTextLabel.Text = quote.author
end

function LoadingScreen.updateBackground(background: { name: string, id: number }): ()
	if not currentLoadingScreenGui then
		warn("Attempt to update the background of the loading screen UI: UI is not created yet.")
		return
	end

	local backgroundImageLabel = currentLoadingScreenGui.Background
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

	local random = Random.new()
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