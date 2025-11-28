--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

--[=[
	@class ParsedObjective
]=]
local ParsedObjective = {}
ParsedObjective.__index = ParsedObjective

export type ParsedObjective = typeof(setmetatable({} :: {
	conditionExpressionStr: string,
	parsedConditionExpression: ExpressionParser.ASTNode?,
	tagExpressionStr: string,
	parsedTagExpression: ExpressionParser.ASTNode?,
	localizedTextKey: string,
}, ParsedObjective))

function ParsedObjective.new(
	conditionExpressionStr: string,
	tagExpressionStr: string,
	localizedTextKey: string
): ParsedObjective
	return setmetatable({
		conditionExpressionStr = conditionExpressionStr,
		parsedConditionExpression = ExpressionParser.fromString(conditionExpressionStr):parse(),
		tagExpressionStr = tagExpressionStr,
		parsedTagExpression = ExpressionParser.fromString(tagExpressionStr):parse(),
		localizedTextKey = localizedTextKey,
	}, ParsedObjective)
end

function ParsedObjective.getConditionExpressionString(self: ParsedObjective): string
	return self.conditionExpressionStr
end

function ParsedObjective.getTagExpressionStr(self: ParsedObjective): string
	return self.tagExpressionStr
end

function ParsedObjective.getLocalizedTextKey(self: ParsedObjective): string
	return self.localizedTextKey
end

--

function ParsedObjective.evaluateCondition(self: ParsedObjective, context: ExpressionContext.ExpressionContext): boolean
	if not self.parsedConditionExpression then
		return true
	end

	if not ExpressionParser.evaluate(self.parsedConditionExpression, context) then
		return false
	else
		return true
	end
end

function ParsedObjective.evaluateTag(self: ParsedObjective, context: ExpressionContext.ExpressionContext): string
	local result = ExpressionParser.evaluate(self.parsedTagExpression, context)
	return tostring(result)
end

return ParsedObjective