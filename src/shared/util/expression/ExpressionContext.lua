--!strict

--[=[
	@class ExpressionContext
]=]
local ExpressionContext = {}
ExpressionContext.__index = ExpressionContext

export type ExpressionContext = typeof(setmetatable({} :: {
	variables: { [string]: any },
	nonStrict: boolean
}, ExpressionContext))

function ExpressionContext.new(variables: { [string]: any }, nonStrict: boolean?): ExpressionContext
	return setmetatable({
		variables = variables,
		nonStrict = nonStrict or false
	}, ExpressionContext)
end

function ExpressionContext.getVariable(self: ExpressionContext, key: string): any
	local v = self.variables[key]
	if v == nil and self.nonStrict then
		warn(`The variable '{key}' does not exist in the context's variables field. Returning nil.`)
		return nil
	elseif v == nil and self.nonStrict ~= false then
		error(`The variable '{key}' does not exist in the context's variables field.`)
	else
		return v
	end
end

return ExpressionContext