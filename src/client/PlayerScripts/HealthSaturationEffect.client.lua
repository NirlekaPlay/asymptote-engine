--!strict

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
colorCorrectionEffect.Parent = currentCamera

local currentCharacter: Model?
local humanoidHealthChangedConnection: RBXScriptConnection?

if localPlayer.Character then
	currentCharacter = localPlayer.Character
end

localPlayer.CharacterAdded:Connect(function(character)
	currentCharacter = character
	local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoidHealthChangedConnection then
		humanoidHealthChangedConnection:Disconnect()
	end
	
	colorCorrectionEffect.Saturation = math.map(humanoid.Health, 0, 100, -1, 0)
	colorCorrectionEffect.Brightness = math.map(humanoid.Health, 0, 100, -0.3, 0)
	colorCorrectionEffect.Contrast = math.map(humanoid.Health, 0, 100, 0.3, 0)
	humanoidHealthChangedConnection = humanoid.HealthChanged:Connect(function(healthValue)
		colorCorrectionEffect.Saturation = math.map(healthValue, 0, 100, -1, 0)
		colorCorrectionEffect.Brightness = math.map(healthValue, 0, 100, -0.3, 0)
		colorCorrectionEffect.Contrast = math.map(healthValue, 0, 100, 0.3, 0)
	end)
end)

localPlayer.CharacterRemoving:Connect(function()
	currentCharacter = nil
end)
