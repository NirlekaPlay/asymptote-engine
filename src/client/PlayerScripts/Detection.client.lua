--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local DetectionMeter = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.DetectionMeter)
local DetectionMeterRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.DetectionMeterRenderer)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)

TypedRemotes.Detection.OnClientEvent:Connect(function(detectionDatas)
	for _, detectionData in ipairs(detectionDatas) do
		DetectionMeter.addOrUpdateNpcsDetectionValue(detectionData)
	end
end)

RunService.PreRender:Connect(function(deltaTime)
	DetectionMeterRenderer.clearBatch()
	DetectionMeter.render(deltaTime)
	DetectionMeterRenderer.renderBatchedCalls()
end)
