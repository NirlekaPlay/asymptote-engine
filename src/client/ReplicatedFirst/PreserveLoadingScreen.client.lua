--!strict

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local arrivedBackgroundId: number? = nil
local arriveTime = os.clock()
local loadedTime: number

local MIN_PRESERVE_TIME = 1

local customLoadingScreen = TeleportService:GetArrivingTeleportGui()
if customLoadingScreen then
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	customLoadingScreen.Parent = playerGui
else
	print("No arriving background ID")
	script:Destroy()
	return
end

local function animateLoadingScreenFadeAndDestroy()
	if not customLoadingScreen then
		return
	end

	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local objectsToAnimate: { [GuiBase]: { [string]: any } } = {}
	for _, guiObject in ipairs(customLoadingScreen:GetDescendants()) do
		if guiObject:IsA("Frame") then
			objectsToAnimate[guiObject] = { BackgroundTransparency = 1 }
		elseif guiObject:IsA("TextLabel") then
			objectsToAnimate[guiObject] = { TextTransparency = 1 }
		elseif guiObject:IsA("ImageLabel") then
			arrivedBackgroundId = tonumber(string.match(guiObject.Image, "%d+"))
			objectsToAnimate[guiObject] = { ImageTransparency = 1, BackgroundTransparency = 1 }
		end
	end

	local firstObjectWaitEvent: RBXScriptSignal<Enum.PlaybackState>? = nil
	for guiObject, properties in pairs(objectsToAnimate) do
		for property, value in pairs(properties) do
			local newTween = TweenService:Create(guiObject, tweenInfo, { [property] = value })
			newTween:Play()
			if not firstObjectWaitEvent then
				firstObjectWaitEvent = newTween.Completed
			end
		end
	end

	if firstObjectWaitEvent then
		firstObjectWaitEvent:Wait()
	end

	customLoadingScreen:Destroy()
end

if arrivedBackgroundId then
	print("Arriving backgroud ID:", arrivedBackgroundId)
else
	print("No arriving background ID")
end

repeat
	task.wait(1)
until game:IsLoaded()
loadedTime = os.clock()
local timeDifference = loadedTime - arriveTime

if timeDifference > MIN_PRESERVE_TIME then
	animateLoadingScreenFadeAndDestroy()
	return
end

task.wait(MIN_PRESERVE_TIME - timeDifference)

animateLoadingScreenFadeAndDestroy()

-- oh we're really doing this are we?
if arrivedBackgroundId then
	local LoadingScreen = require(Players.LocalPlayer.PlayerScripts:WaitForChild("client"):WaitForChild("modules"):WaitForChild("ui"):WaitForChild("LoadingScreen"))
	LoadingScreen.setLastArrivedBackgroundId(arrivedBackgroundId :: number)
end

script:Destroy()