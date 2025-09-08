--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local BulletTracerHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.BulletTracerHandler)
local HitMarkerHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.HitMarkerHandler)
local ShellDropHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.ShellDropHandler)
local GunSysTypedRemotes = require(ReplicatedStorage.shared.network.remotes.GunSysTypedRemotes)

GunSysTypedRemotes.BulletTracer.OnClientEvent:Connect(BulletTracerHandler.onReceiveTracerData)
GunSysTypedRemotes.DropShell.OnClientEvent:Connect(ShellDropHandler.onReceiveDropShellCall)
GunSysTypedRemotes.HitRegister.OnClientEvent:Connect(HitMarkerHandler.onHitRegistered)

return {}