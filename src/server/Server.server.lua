local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TargetNearbySensor = require(ServerScriptService.Server.ai.sensing.TargetNearbySensor)
local SuspicionManagement = require(ServerScriptService.Server.ai.suspicion.SuspicionManagement)

local rig: Model = workspace:WaitForChild("Rig")
local currentSusMan = SuspicionManagement.new()
local currentNearbySensor = TargetNearbySensor.new(20)

RunService.PreAnimation:Connect(function(deltaTime)
	currentNearbySensor:update(rig.PrimaryPart.Position)	
	currentSusMan:update(deltaTime, currentNearbySensor.detectedTargets)
end)