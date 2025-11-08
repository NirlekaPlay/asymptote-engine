--!strict

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local BulletTracerHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.BulletTracerHandler)
local HitMarkerHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.HitMarkerHandler)
local ShellDropHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.ShellDropHandler)
local GunSystClientPacketListener = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.network.GunSysClientPacketListener)

RunService.PreRender:Connect(function(deltaTime)
	HitMarkerHandler.update()
	BulletTracerHandler.update(deltaTime)
	ShellDropHandler.update(deltaTime)
end)