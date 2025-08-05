--!strict

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
colorCorrectionEffect.Parent = currentCamera

local currentCharacter: Model?
local humanoidHealthChangedConnection: RBXScriptConnection?
local vignetteScreenGui = localPlayer.PlayerGui:FindFirstChild("Vignette") :: ScreenGui?

if localPlayer.Character then
	currentCharacter = localPlayer.Character
end

local function createVignetteGui(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	screenGui.Name = "Vignette"

	local vignetteImage = Instance.new("ImageLabel")
	vignetteImage.BackgroundTransparency = 1
	vignetteImage.Size = UDim2.fromScale(1, 1)
	vignetteImage.ImageContent = Content.fromAssetId(15447075793)
	vignetteImage.ScaleType = Enum.ScaleType.Stretch
	vignetteImage.ImageTransparency = 1
	vignetteImage.Parent = screenGui

	screenGui.Parent = localPlayer.PlayerGui

	return screenGui
end

if not vignetteScreenGui then
	vignetteScreenGui = createVignetteGui()
end

local function updateHealthEffects(currentHealth: number)
	colorCorrectionEffect.Saturation = math.map(currentHealth, 0, 100, -1, 0)
	colorCorrectionEffect.Brightness = math.map(currentHealth, 0, 100, -0.3, 0)
	colorCorrectionEffect.Contrast = math.map(currentHealth, 0, 100, 0.3, 0)

	if not vignetteScreenGui then return end
	(vignetteScreenGui:FindFirstChild("ImageLabel") :: ImageLabel)
		.ImageTransparency = math.map(currentHealth, 0, 100, 0, 1)
end

localPlayer.CharacterAdded:Connect(function(character)
	currentCharacter = character
	local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoidHealthChangedConnection then
		humanoidHealthChangedConnection:Disconnect()
	end
	
	updateHealthEffects(humanoid.Health)
	humanoidHealthChangedConnection = humanoid.HealthChanged:Connect(function(healthValue)
		updateHealthEffects(healthValue)
	end)
end)

localPlayer.CharacterRemoving:Connect(function()
	currentCharacter = nil
end)
