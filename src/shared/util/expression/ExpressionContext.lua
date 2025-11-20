--!strict

--[=[
	@class ExpressionContext
]=]
local ExpressionContext = {}
ExpressionContext.__index = ExpressionContext

export type ExpressionContext = typeof(setmetatable({} :: {
	variables: { [string]: any }
}, ExpressionContext))

function ExpressionContext.new(variables: { [string]: any }): ExpressionContext
	return setmetatable({
		variables = variables
	}, ExpressionContext)
end

function ExpressionContext.getVariable(self: ExpressionContext, key: string): any
	local v = self.variables[key]
	if v == nil then
		error(`The variable '{key}' does not exist in the context's variables field.`)
	else
		return v
	end
end

return ExpressionContext