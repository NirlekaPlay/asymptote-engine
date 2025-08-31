--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local BulletHitHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.BulletHitHandler)
local HitMarkerHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.HitMarkerHandler)
local ShellDropHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.ShellDropHandler)
local GunSysTypedRemotes = require(ReplicatedStorage.shared.network.GunSysTypedRemotes)

GunSysTypedRemotes.BulletHit.OnClientEvent:Connect(BulletHitHandler.handleBulletHit)
GunSysTypedRemotes.DropShell.OnClientEvent:Connect(ShellDropHandler.onReceiveDropShellCall)
GunSysTypedRemotes.HitRegister.OnClientEvent:Connect(HitMarkerHandler.onHitRegistered)

return {}