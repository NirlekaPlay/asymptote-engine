--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local GunControl = require(ServerScriptService.server.ai.control.GunControl)

export type ArmedAgent = {
	getGunControl: (self: ArmedAgent) -> GunControl.GunControl
}

return nil