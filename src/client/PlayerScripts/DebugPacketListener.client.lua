--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local DebugPacketTypes = require(ReplicatedStorage.shared.network.DebugPacketTypes)
local ComputedVoxelsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.debug.ComputedVoxelsRenderer)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

TypedRemotes.ClientBoundDynamicDebugDump.OnClientEvent:Connect(function(debugName, payload)
	if debugName == DebugPacketTypes.DEBUG_COMPUTED_VOXELS then
		-- "Trust me bro"
		ComputedVoxelsRenderer.visualizeComputedNodes(payload)
	end
end)
