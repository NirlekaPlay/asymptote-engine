--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PersistentInstanceManager = require(ServerScriptService.server.world.level.PersistentInstanceManager)

export type ServerLevel = {
	getPersistentInstanceManager: (self: ServerLevel) -> PersistentInstanceManager.PersistentInstanceManager
}

return nil