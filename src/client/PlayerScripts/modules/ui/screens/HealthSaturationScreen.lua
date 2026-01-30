--!strict

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

--[=[
	@class HealthSaturationScreen

	I hereby justify the use of AI to write this file.
	Because uh
	Prevents brain damage for me at this condition.
]=]
local HealthSaturationScreen = {}

local colorCorrectionEffect: ColorCorrectionEffect
local healthConnection: RBXScriptConnection?
local cameraConnection: RBXScriptConnection?
local vignetteGui: ScreenGui?
local vignetteImage: ImageLabel?

local function updateHealthEffects(currentHealth: number)
	colorCorrectionEffect.Saturation = math.map(currentHealth, 0, 100, -1, 0)
	colorCorrectionEffect.Brightness = math.map(currentHealth, 0, 100, -0.2, 0)
	colorCorrectionEffect.Contrast = math.map(currentHealth, 0, 100, 1, 0)

	if vignetteImage then
		vignetteImage.ImageTransparency = math.map(currentHealth, 0, 100, 0.6, 1)
	end
end

local function setupVignette()
	if vignetteGui then return end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Vignette"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://15629026059"
	image.ScaleType = Enum.ScaleType.Stretch
	image.ImageTransparency = 1
	image.Parent = screenGui
	
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
	vignetteGui = screenGui
	vignetteImage = image
end

local function syncCameraEffect()
	local cam = workspace.CurrentCamera
	local existing = cam:FindFirstChild("HealthSaturationEffect")
	
	if existing and existing:IsA("ColorCorrectionEffect") then
		colorCorrectionEffect = existing
	else
		colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
		colorCorrectionEffect.Name = "HealthSaturationEffect"
		colorCorrectionEffect.Parent = cam
	end
end

local function connectHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then return end

	if healthConnection then healthConnection:Disconnect() end
	
	healthConnection = humanoid.HealthChanged:Connect(function(health)
		updateHealthEffects(health)
	end)
	
	updateHealthEffects(humanoid.Health)
end

function HealthSaturationScreen.enable()
	setupVignette()
	syncCameraEffect()
	
	-- Handle Camera edge case (Effect must be child of CurrentCamera to render)
	cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		syncCameraEffect()
		if localPlayer.Character then
			local hum = (localPlayer.Character :: Model):FindFirstChildOfClass("Humanoid")
			if hum then updateHealthEffects(hum.Health) end
		end
	end)

	localPlayer.CharacterAdded:Connect(connectHealth)
	if localPlayer.Character then connectHealth(localPlayer.Character :: Model) end
end

function HealthSaturationScreen.disable()
	if healthConnection then healthConnection:Disconnect() end
	if cameraConnection then cameraConnection:Disconnect() end

	updateHealthEffects(100)
end

return HealthSaturationScreen