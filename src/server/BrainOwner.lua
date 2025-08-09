--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Brain = require(ServerScriptService.server.ai.Brain)

export type BrainOwner = {
	getBrain: (self: BrainOwner) -> Brain.Brain<any>,
}

return {}