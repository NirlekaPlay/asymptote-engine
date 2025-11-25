--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local LevelInstancesAccessor = require(ServerScriptService.server.world.level.LevelInstancesAccessor)
local PersistentInstanceManager = require(ServerScriptService.server.world.level.PersistentInstanceManager)
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)

export type ServerLevel = {
	getPersistentInstanceManager: (self: ServerLevel) -> PersistentInstanceManager.PersistentInstanceManager,
	getServerLevelInstancesAccessor: (self: ServerLevel) -> LevelInstancesAccessor.LevelInstancesAccessor,
	getCellManager: (self: ServerLevel) -> CellManager.CellManager
}

return nil