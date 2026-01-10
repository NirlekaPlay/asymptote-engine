--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)

CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Captures, false)
CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.PlayerList, false)
CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.EmotesMenu, false)
CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Health, false)