--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local SCREEN_GUI_NAME = "Transition"
local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
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

	task.wait(TWEEN_INFO.Time)

	for _, tween in currentTransitionUi.tweensForHide do
		tween:Play()
	end

	task.delay(TWEEN_INFO.Time, currentTransitionUi.endFunc)
end

function Transition.createTransitionUi(): {
	setupFunc: () -> (), endFunc: () -> (), tweensForShow: {Tween}, tweensForHide: {Tween} 
}
	local screenGui = Transition.getScreenGui()

	local rootFrame = Instance.new("Frame")
	rootFrame.BackgroundColor3 = TRANSITION_FRAME_COLOR
	rootFrame.BackgroundTransparency = 0
	rootFrame.Position = UDim2.fromScale(0, 0)
	rootFrame.Size = UDim2.fromScale(1, 0)
	rootFrame.BorderSizePixel = 0
	rootFrame.Parent = screenGui

	local tweensForShow: {Tween} = {}

	table.insert(tweensForShow, TweenService:Create(rootFrame, TWEEN_INFO, { Size = UDim2.fromScale(1, 1) }))

	local tweensForHide: {Tween} = {}

	table.insert(tweensForHide, TweenService:Create(rootFrame, TWEEN_INFO, { Position = UDim2.fromScale(0, 1) }))
	table.insert(tweensForHide, TweenService:Create(rootFrame, TWEEN_INFO, { Size = UDim2.fromScale(1, 1) }))

	local function setupTransition(): ()
		rootFrame.Visible = true
		rootFrame.Position = UDim2.fromScale(0, 0)
		rootFrame.Size = UDim2.fromScale(1, 0)
	end

	local function endTransition(): ()
		rootFrame.Visible = false
	end

	return { setupFunc = setupTransition, endFunc = endTransition, tweensForShow = tweensForShow, tweensForHide = tweensForHide }
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