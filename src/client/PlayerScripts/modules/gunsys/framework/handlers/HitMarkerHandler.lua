--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer.PlayerGui

local HIT_MARKER_SCREENGUI = localPlayerGui:WaitForChild("Hitmarker")
local HIT_MARKER_SOUND = ReplicatedStorage.shared.assets.sounds.gunsys.hit_marker
local HIT_MARKER_TRANSPARENCY_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local HIT_MARKER_SIZE_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local HIT_MARKER_INIT_SIZE = HIT_MARKER_SCREENGUI.Hitmarker.UIScale.Scale
local hitMarkerTransTween = TweenService:Create(
	HIT_MARKER_SCREENGUI.Hitmarker, HIT_MARKER_TRANSPARENCY_TWEEN_INFO, { GroupTransparency = 1}
)
local hitMarkerSizeTween = TweenService:Create(
	HIT_MARKER_SCREENGUI.Hitmarker.UIScale, HIT_MARKER_SIZE_TWEEN_INFO, { Scale = HIT_MARKER_INIT_SIZE * 1.2}
)
local RED = Color3.fromRGB(200, 0, 50)
local WHITE = Color3.new(1, 1, 1)

--[=[
	@class HitMarkerHandler
]=]
local HitMarkerHandler = {}

function HitMarkerHandler.onHitRegistered(causedDeath: boolean): ()
	local hitMarkerColor = causedDeath and RED or WHITE
	hitMarkerTransTween:Cancel()
	hitMarkerSizeTween:Cancel()
	for _, frame in pairs(HIT_MARKER_SCREENGUI.Hitmarker:GetChildren()) do
		if frame:IsA("Frame") then
			frame.BackgroundColor3 = hitMarkerColor
		end
	end
	HIT_MARKER_SCREENGUI.Hitmarker.UIScale.Scale = HIT_MARKER_INIT_SIZE
	HIT_MARKER_SCREENGUI.Hitmarker.GroupTransparency = 0
	hitMarkerTransTween:Play()
	hitMarkerSizeTween:Play()
	task.defer(function()
		task.wait(0.2)
		HIT_MARKER_SOUND:Play()
	end)
end

function HitMarkerHandler.update(): ()
	if HIT_MARKER_SCREENGUI.Hitmarker.GroupTransparency <= 0 then
		return
	end

	local vec2 = UserInputService:GetMouseLocation()
	HIT_MARKER_SCREENGUI.Hitmarker.Position = UDim2.fromOffset(vec2.X, vec2.Y)
end

return HitMarkerHandler