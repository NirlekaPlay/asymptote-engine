--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)
local UString = require(ReplicatedStorage.shared.util.string.UString)

local DEFAULT_TRIGGER_ONCE = true

--[=[
	@class DialogueConceptTrigger

	Used to trigger dialogues.
]=]
local DialogueConceptTrigger = {}
DialogueConceptTrigger.__index = DialogueConceptTrigger

export type DialogueConceptTrigger = StateComponent.StateComponent & typeof(setmetatable({} :: {
	parsedActive: ExpressionParser.ASTNode,
	triggerOnce: boolean,
	conceptName: string,
	statesChangedConn: RBXScriptConnection?,
}, DialogueConceptTrigger))

function DialogueConceptTrigger.fromInstance(inst: Instance, context: ExpressionContext.ExpressionContext): DialogueConceptTrigger
	local conceptName = inst:GetAttribute("ConceptName") :: string?
	if not conceptName or UString.isBlank(conceptName) then
		error(`'ConceptName' cannot be empty or blank`)
	end

	local parsedActive: ExpressionParser.ASTNode?
	local activeStr = inst:GetAttribute("Active") :: string?
	if activeStr and not UString.isBlank(activeStr) then
		parsedActive = ExpressionParser.fromString(activeStr):parse()
	end

	if not parsedActive then
		error(`ERR_ACTIVE_PARSE_NIL`) -- Too lazy
	end

	local vars = ExpressionParser.getVariablesSet(parsedActive)
	local triggerOnce = inst:GetAttribute("TriggerOnce") :: boolean? or DEFAULT_TRIGGER_ONCE

	local conn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
		if vars[stateName] then
			local evaluated = ExpressionParser.evaluate(parsedActive, context)
			if evaluated then
				TypedRemotes.ClientBoundDialogueConceptEvaluate:FireAllClients(conceptName, GlobalStatesHolder.getAllStatesReference())
			end
		end
	end)

	return setmetatable({
		parsedActive = parsedActive,
		triggerOnce = triggerOnce,
		conceptName = conceptName,
		statesChangedConn = conn
	}, DialogueConceptTrigger) :: DialogueConceptTrigger
end

function DialogueConceptTrigger.onLevelRestart(self: DialogueConceptTrigger): ()
	return
end

return DialogueConceptTrigger