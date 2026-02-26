local StarterPlayer = game:GetService("StarterPlayer")
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)
require(StarterPlayer.StarterPlayerScripts.client.modules.cinematic.ClientCinematics)
CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, false)