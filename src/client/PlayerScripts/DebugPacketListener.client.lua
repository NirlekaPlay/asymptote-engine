--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ComputedVoxelsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.debug.ComputedVoxelsRenderer)
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

TypedRemotes.ClientBoundDynamicDebugDump.OnClientEvent:Connect(function(debugName, payload)
	if debugName == DebugPackets.Packets.DEBUG_COMPUTED_VOXELS then
		-- "Trust me bro"
		ComputedVoxelsRenderer.visualizeComputedNodes(payload)
	end
end)
