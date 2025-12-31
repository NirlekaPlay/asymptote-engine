--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)

export type StateComponent = {
	fromInstance: (instance: Instance, context: ExpressionContext.ExpressionContext) -> StateComponent
}

return nil