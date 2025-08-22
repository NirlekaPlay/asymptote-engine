--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local SharedConstants = require(StarterPlayer.StarterPlayerScripts.client.modules.SharedConstants)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local BrainDebugRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.debug.BrainDebugRenderer)
local DebugRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.debug.DebugRenderer)
local RTween = require(StarterPlayer.StarterPlayerScripts.client.modules.interpolation.RTween)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)

local currentDebugRendererIndicator: ScreenGui
local currentDebugRendererText: TextLabel
local currentDebugRendererTextShadow: TextLabel
local tween = RTween.create(Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
local showTextFor = 0
local currentTween: RTween.RTween? = nil

local function createNewDebugRendererIndicator(): ()
	currentDebugRendererIndicator = Instance.new("ScreenGui")
	currentDebugRendererIndicator.Name = "DebugRendererIndicator"
	currentDebugRendererIndicator.IgnoreGuiInset = true
	currentDebugRendererIndicator.ResetOnSpawn = false
	currentDebugRendererIndicator.Parent = Players.LocalPlayer.PlayerGui

	currentDebugRendererText = Instance.new("TextLabel")
	currentDebugRendererText.AnchorPoint = Vector2.new(0.5, 0.5)
	currentDebugRendererText.BackgroundTransparency = 1
	currentDebugRendererText.Position = UDim2.fromScale(0.5, 0.852)
	currentDebugRendererText.Size = UDim2.fromScale(1, 0.044)
	currentDebugRendererText.TextColor3 = Color3.new(1, 1, 1)
	currentDebugRendererText.TextScaled = true
	currentDebugRendererText.TextTransparency = 1
	currentDebugRendererText.Parent = currentDebugRendererIndicator

	currentDebugRendererTextShadow = UITextShadow.createTextShadow(currentDebugRendererText, nil, 1.5)
	currentDebugRendererTextShadow.TextTransparency = 1
end

createNewDebugRendererIndicator()

local function onDebugRendererChanged(debugRendererName: string, enabled: boolean): ()
	if currentTween and currentTween.is_playing then
		currentTween:kill()
		currentTween = nil
	end

	currentDebugRendererText.Text = "Debug renderer: " .. debugRendererName 
	if enabled then
		currentDebugRendererText.Text = currentDebugRendererText.Text .. " enabled"
	else
		currentDebugRendererText.Text = currentDebugRendererText.Text .. " disabled"
	end
	currentDebugRendererTextShadow.Text = currentDebugRendererText.Text
	currentDebugRendererText.TextTransparency = 0
	currentDebugRendererTextShadow.TextTransparency = 0.7
	
	showTextFor = 2
end

DebugRenderer.addSimpleDebugRenderer(BrainDebugRenderer)

TypedRemotes.BrainDebugDump.OnClientEvent:Connect(function(brainDumps)
	if SharedConstants.DEBUG_BRAIN then
		for _, brainDump in ipairs(brainDumps) do
			BrainDebugRenderer.addOrUpdateBrainDump(brainDump)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.N then
		SharedConstants.DEBUG_BRAIN = not SharedConstants.DEBUG_BRAIN
		TypedRemotes.SubscribeDebugDump:FireServer("DEBUG_BRAIN", SharedConstants.DEBUG_BRAIN)
		if not SharedConstants.DEBUG_BRAIN then
			DebugRenderer.removeSimpleDebugRenderer(BrainDebugRenderer)
			BrainDebugRenderer.clear()
		else
			DebugRenderer.addSimpleDebugRenderer(BrainDebugRenderer)
		end
		onDebugRendererChanged("aiBrainDebugRenderer", SharedConstants.DEBUG_BRAIN)
	end
end)

RunService.PreRender:Connect(function(deltaTime)
	DebugRenderer.render()

	if showTextFor > 0 then
		showTextFor -= deltaTime

		if showTextFor <= 0 and (not currentTween or not currentTween.is_playing) then
			tween:set_parallel(true)
			tween:tween_instance(
				currentDebugRendererText, { TextTransparency = 1 }, 1
			)
			tween:tween_instance(
				currentDebugRendererTextShadow, { TextTransparency = 1 }, 1
			)
			currentTween = tween
			tween:play()
		end
	end
end)