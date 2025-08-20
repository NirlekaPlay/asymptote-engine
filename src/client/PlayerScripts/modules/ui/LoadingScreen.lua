--!strict

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.core.CoreCall)
local QuoteOfTheDay = require(script.Parent.QuoteOfTheDay)
local UITextShadow = require(script.Parent.UITextShadow)

local LOADING_SCREEN_SCREEN_GUI_NAME = "LoadingScreen"
local LOADING_SCREEN_BACKGROUND_IDS = {
	{ name = "Hub Room", id = 93100734007160 },
	{ name = "The Founder's Eye", id = 119595682823582 },
	{ name = "She's Dead", id = 129935296812180 },
	{ name = "A Tester's Favorite Item", id = 112033098640768 }
}
local TWEEN_INFO_FADE = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local lastArrivedBackgroundId: number? = nil

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentLoadingScreenGui: ScreenGui

--[=[
	@class LoadingScreen

	Manages the UI you see when teleporting accross places.
]=]
local LoadingScreen = {}

function LoadingScreen.onTeleporting(delay: number, teleportCallback: () -> ())
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
				guiObject, TWEEN_INFO_FADE, { TextTransparency = 0}
			)
			table.insert(tweens, newTween)

			if not trackingTween then
				trackingTween = newTween
			end
		elseif guiObject:IsA("ImageLabel") then
			guiObject.ImageTransparency = 1
			guiObject.BackgroundTransparency = 1
			local newTween = TweenService:Create(
				guiObject, TWEEN_INFO_FADE, { ImageTransparency = 0}
			)
			table.insert(tweens, newTween)

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
	quoteAuthorText.TextXAlignment = Enum.TextXAlignment.Left
	quoteAuthorText.Text = quoteOfTheDay.author
	quoteAuthorText.ZIndex = 3
	quoteAuthorText.Parent = rootFrame

	UITextShadow.createTextShadow(quoteAuthorText, nil, 1.5, nil, 0.5)

	newScreenGui.Enabled = true
	newScreenGui.Parent = playerGui

	return newScreenGui
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

return LoadingScreen