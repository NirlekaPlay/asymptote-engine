--!strict

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local ShellDropHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.ShellDropHandler)
local GunSystClientPacketListener = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.network.GunSysClientPacketListener)

RunService.PreRender:Connect(function(deltaTime)
	ShellDropHandler.update(deltaTime)
end)
