local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local TargetNearbySensor = require(ServerScriptService.server.ai.sensing.TargetNearbySensor)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local TriggerZone = require(ServerScriptService.server.zone.TriggerZone)

local rig: Model = workspace:WaitForChild("Rig")
local currentSusMan = SuspicionManagement.new(rig)
local currentNearbySensor = TargetNearbySensor.new(20)
local currentTriggerZone = TriggerZone.fromPart(workspace:WaitForChild("Zone1"))
local currentBodyRotCtrl = BodyRotationControl.new(rig.HumanoidRootPart)

RunService.PreAnimation:Connect(function(deltaTime)
	currentTriggerZone:update()
	currentNearbySensor:update(rig.PrimaryPart.Position, currentTriggerZone:getPlayersInZone())
	currentSusMan:update(deltaTime, currentNearbySensor.detectedTargets)
	if currentSusMan.currentState == "SUSPICIOUS" then
		currentBodyRotCtrl:setRotateTowards(currentSusMan.focusingSuspect.Character.PrimaryPart.Position)
	else
		currentBodyRotCtrl:setRotateTowards(nil)
	end
	currentBodyRotCtrl:update(deltaTime)
end)