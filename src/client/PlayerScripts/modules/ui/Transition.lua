--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local SCREEN_GUI_NAME = "Transition"
local TRANSITION_FRAME_COLOR = Color3.new(0.090196, 0.090196, 0.090196)

--[=[
	@class Transition
]=]
local Transition = {}

local currentTransitionUi: typeof(Transition.createTransitionUi())

function Transition.transition(): ()
	if not currentTransitionUi then
		currentTransitionUi = Transition.createTransitionUi()
	end

	currentTransitionUi.setupFunc()

	for _, tween in currentTransitionUi.tweensForShow do
		tween:Play()
	end

	task.wait(1)

	for _, tween in currentTransitionUi.tweensForHide do
		tween:Play()
	end
end

function Transition.createTransitionUi(): { setupFunc: () -> (), tweensForShow: {Tween}, tweensForHide: {Tween} }
	local screenGui = Transition.getScreenGui()

	local rootFrame = Instance.new("Frame")
	rootFrame.BackgroundColor3 = TRANSITION_FRAME_COLOR
	rootFrame.BackgroundTransparency = 0
	rootFrame.Position = UDim2.fromScale(0, 0)
	rootFrame.Size = UDim2.fromScale(1, 0)
	rootFrame.Parent = screenGui

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)

	local tweensForShow: {Tween} = {}

	table.insert(tweensForShow, TweenService:Create(rootFrame, tweenInfo, { Size = UDim2.fromScale(1, 1) }))

	local tweensForHide: {Tween} = {}

	table.insert(tweensForHide, TweenService:Create(rootFrame, tweenInfo, { Position = UDim2.fromScale(0, 1) }))
	table.insert(tweensForHide, TweenService:Create(rootFrame, tweenInfo, { Size = UDim2.fromScale(1, 1) }))

	local function setupTransition(): ()
		rootFrame.Position = UDim2.fromScale(0, 0)
		rootFrame.Size = UDim2.fromScale(1, 0)
	end

	return { setupFunc = setupTransition, tweensForShow = tweensForShow, tweensForHide = tweensForHide }
end

function Transition.getScreenGui(): ScreenGui
	local existingScreenGui = playerGui:FindFirstChild(SCREEN_GUI_NAME) :: ScreenGui?
	if not existingScreenGui then
		local newScreenGui = Instance.new("ScreenGui")
		newScreenGui.DisplayOrder = 999999
		newScreenGui.IgnoreGuiInset = true
		newScreenGui.ResetOnSpawn = false
		newScreenGui.Name = SCREEN_GUI_NAME
		newScreenGui.Parent = playerGui
		return newScreenGui
	else
		return existingScreenGui
	end
end

return Transition