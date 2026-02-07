--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)

export type StateComponent = {
	fromInstance: (instance: Instance, context: ExpressionContext.ExpressionContext) -> StateComponent,
	update: ((self: StateComponent, deltaTime: number, serverLevel: ServerLevel.ServerLevel) -> ())?,
	destroy: ((self: StateComponent, serverLevel: ServerLevel.ServerLevel) -> ())?
}

return nil