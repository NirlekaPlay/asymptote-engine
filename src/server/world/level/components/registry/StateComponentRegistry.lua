--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ElevatorShaftController = require(ServerScriptService.server.world.level.components.ElevatorShaftController)
local MusicController = require(ServerScriptService.server.world.level.components.MusicController)
local NpcStateTracker = require(ServerScriptService.server.world.level.components.NpcStateTracker)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)

return {
	MusicController = MusicController.fromInstance,
	NpcStateTracker = NpcStateTracker.fromInstance,
	ElevatorShaftController = ElevatorShaftController.fromInstance
} :: { [string]: (instance: Instance, context: ExpressionContext.ExpressionContext) -> StateComponent.StateComponent }