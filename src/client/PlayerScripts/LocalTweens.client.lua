--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalTweenPayload = require(ReplicatedStorage.shared.network.payloads.LocalTweenPayload)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local function deserializeTweenInfo(serialized: LocalTweenPayload.SerializedTweenInfo): TweenInfo
	return TweenInfo.new(
		serialized.time,
		serialized.easingStyle,
		serialized.easingDirection,
		serialized.repeatCount,
		serialized.reverses,
		serialized.delayTime
	)
end

TypedRemotes.ClientBoundTween.OnClientEvent:Connect(function(payload)
	if not payload.instance or not payload.instance:IsDescendantOf(game) then
		return
	end

	TweenService:Create(
		payload.instance, deserializeTweenInfo(payload.tweenInfo), payload.properties
	):Play()
end)
