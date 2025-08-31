--!strict

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
colorCorrectionEffect.Parent = currentCamera

local currentCharacter: Model?
local humanoidHealthChangedConnection: RBXScriptConnection?
local vignetteScreenGui = localPlayer.PlayerGui:FindFirstChild("Vignette") :: ScreenGui?

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

local function resetHealthEffects()
	updateHealthEffects(100)
end

local function connectToCharacterHealth(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoidHealthChangedConnection then
		humanoidHealthChangedConnection:Disconnect()
		humanoidHealthChangedConnection = nil
	end

	updateHealthEffects(humanoid.Health)

	humanoidHealthChangedConnection = humanoid.HealthChanged:Connect(function(healthValue)
		updateHealthEffects(healthValue)
	end)
end

if localPlayer.Character then
	currentCharacter = localPlayer.Character
	connectToCharacterHealth(currentCharacter)
end

localPlayer.CharacterAdded:Connect(function(character)
	currentCharacter = character
	connectToCharacterHealth(character)
end)

localPlayer.CharacterRemoving:Connect(function()
	if humanoidHealthChangedConnection then
		humanoidHealthChangedConnection:Disconnect()
		humanoidHealthChangedConnection = nil
	end

	resetHealthEffects()
	
	currentCharacter = nil
end)