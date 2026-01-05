--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueConcept = require(ReplicatedStorage.shared.dialogue.DialogueConcept)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local registry: { [string]: { DialogueConcept } } = {}

--[=[
	@class DialogueSequenceEvaluator
]=]
local DialogueSequenceEvaluator = {}

type DialogueConcept = DialogueConcept.DialogueConcept

function DialogueSequenceEvaluator.setRegistry(reg: { [string]: { DialogueConcept } }): ()
	registry = reg
end

function DialogueSequenceEvaluator.getBestConceptResponse(conceptName: string, context: ExpressionContext.ExpressionContext): DialogueConcept?
	local rules = registry[conceptName]
	if not rules then return nil end

	for _, rule in rules do
		local success, result = pcall(function()
			local parsed = ExpressionParser.fromString(rule.condition):parse()
			return ExpressionParser.evaluate(parsed, context)
		end)

		if success and result then
			return rule
		end
	end

	return nil
end

return DialogueSequenceEvaluator