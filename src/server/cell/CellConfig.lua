--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)

export type Config = {
	canBeTrespassed: boolean,
	penalties: {
		disguised: PlayerStatus.PlayerStatusType?,
		undisguised: PlayerStatus.PlayerStatusType?
	}
}

return nil