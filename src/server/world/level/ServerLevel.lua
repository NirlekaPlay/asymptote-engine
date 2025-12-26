--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local LevelInstancesAccessor = require(ServerScriptService.server.world.level.LevelInstancesAccessor)
local PersistentInstanceManager = require(ServerScriptService.server.world.level.PersistentInstanceManager)
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)
local MissionManagerInterface = require(ServerScriptService.server.world.level.mission.MissionManagerInterface)
local SoundDispatcher = require(ServerScriptService.server.world.sound.SoundDispatcher)

export type ServerLevel = {
	getExpressionContext: (self: ServerLevel) -> ExpressionContext.ExpressionContext,
	getPersistentInstanceManager: (self: ServerLevel) -> PersistentInstanceManager.PersistentInstanceManager,
	getServerLevelInstancesAccessor: (self: ServerLevel) -> LevelInstancesAccessor.LevelInstancesAccessor,
	getSoundDispatcher: (self: ServerLevel) -> SoundDispatcher.SoundDispatcher,
	getCellManager: (self: ServerLevel) -> CellManager.CellManager,
	getMissionManager: (self: ServerLevel) -> MissionManagerInterface.MissionManagerInterface,
	isRestarting: (self: ServerLevel) -> boolean,
	restartLevel: (self: ServerLevel) -> ()
}

return nil