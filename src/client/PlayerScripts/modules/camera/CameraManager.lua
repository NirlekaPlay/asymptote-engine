--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)
local SmoothValue = require(ReplicatedStorage.shared.thirdparty.smooth.SmoothValue)
local EaseFunc = require(ReplicatedStorage.shared.util.animation.EaseFunc)

local ease = EaseFunc
local lerp = math.lerp

local camera = workspace.CurrentCamera
local currentFov: number
local currentSocket: CameraSocket.CameraSocket
local dur = 1.5
local elapsed = 0
local moving = false
local tiltMouse = false

local maxTilt = 10
local smoothTime = 0.5
local smoothTiltX = SmoothValue.new(Vector3.new(0, 0, 0), smoothTime)
local smoothTiltY = SmoothValue.new(Vector3.new(0, 0, 0), smoothTime)

local viewSize = camera.ViewportSize
local viewSizeX = viewSize.X
local viewSizeY = viewSize.Y

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local newViewSize = camera.ViewportSize
	viewSizeX = newViewSize.X
	viewSizeY = newViewSize.Y
end)

--[=[
	@class CameraManager
]=]
local CameraManager = {}

function CameraManager.takeOverCamera(): ()
	camera.CameraType = Enum.CameraType.Scriptable
end

function CameraManager.restoreToDefaultBehavior(): ()
	camera.CameraType = Enum.CameraType.Custom
end

function CameraManager.update(deltaTime: number)
	CameraManager.lerpMovement(deltaTime)
	CameraManager.tiltCameraToMouse(deltaTime)
end

function CameraManager.startTilting()
	tiltMouse = true
end

function CameraManager.stopTilting()
	tiltMouse = false
end

function CameraManager.setSocket(socket: CameraSocket.CameraSocket)
	local activeSocket = socket
	if activeSocket then
		currentSocket = activeSocket
		camera.CFrame = activeSocket.cframe
		camera.FieldOfView = activeSocket.fov
	end
end

function CameraManager.beginLerp()
	local activeSocket = currentSocket
	if activeSocket then
		currentSocket = activeSocket
		currentFov = camera.FieldOfView
		elapsed = 0
		moving = true
	end
end

function CameraManager.lerpMovement(dt: number)
	if moving then
		elapsed += dt
		local c = math.clamp(elapsed / dur, 0.0, 1.0)
		c = ease(c, 0.2)
		local cframe = camera.CFrame:Lerp(currentSocket.cframe, c)
		local fov = lerp(currentFov, currentSocket.fov, c)
		camera.FieldOfView = fov
		camera.CFrame = cframe

		if camera.CFrame == cframe and camera.FieldOfView == fov then
			moving = false
		end
	end
end

function CameraManager.tiltCameraToMouse()
	if tiltMouse then
		local mouseLocation = UserInputService:GetMouseLocation()
		local goalTiltX = (((mouseLocation.Y - viewSizeY / 2) / viewSizeY) * -maxTilt)
		local goalTiltY = (((mouseLocation.X - viewSizeX / 2) / viewSizeX) * -maxTilt)

		local smoothX = smoothTiltX:update(Vector3.new(math.rad(goalTiltX), 0, 0))
		local smoothY = smoothTiltY:update(Vector3.new(0, math.rad(goalTiltY), 0))

		camera.CFrame = currentSocket.cframe * CFrame.Angles(
			smoothX.X,
			smoothY.Y,
			0
		)
	end
end

return CameraManager