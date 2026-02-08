--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
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
	activeUsedVars: { [string]: any },
	triggerOnce: boolean,
	conceptName: string,
	statesChangedConn: RBXScriptConnection?,
	context: ExpressionContext.ExpressionContext -- Fucking circular dependency bullshit
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

	local self = setmetatable({
		parsedActive = parsedActive,
		triggerOnce = triggerOnce,
		conceptName = conceptName,
		statesChangedConn = nil :: RBXScriptConnection?,
		activeUsedVars = vars,
		context = context
	}, DialogueConceptTrigger) :: DialogueConceptTrigger

	self.statesChangedConn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
		self:onStatesChanged(stateName, stateValue)
	end)

	return self
end

function DialogueConceptTrigger.onLevelRestart(self: DialogueConceptTrigger): ()
	if self.triggerOnce and not self.statesChangedConn then
		self.statesChangedConn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
			self:onStatesChanged(stateName, stateValue)
		end)
	end
end

function DialogueConceptTrigger.onStatesChanged(self: DialogueConceptTrigger, varName: string, varValue: any): ()
	if self.activeUsedVars[varName] then
		local evaluated = ExpressionParser.evaluate(self.parsedActive, self.context)
		if evaluated then
			local vars = GlobalStatesHolder.getAllStatesReference()
			TypedRemotes.ClientBoundDialogueConceptEvaluate:FireAllClients(self.conceptName, vars)

			if not self.triggerOnce then
				return
			end

			if not self.statesChangedConn then
				return
			end

			(self.statesChangedConn :: RBXScriptConnection):Disconnect()
			self.statesChangedConn = nil
		end
	end
end

--

function DialogueConceptTrigger.destroy(self: DialogueConceptTrigger, serverLevel: ServerLevel.ServerLevel): ()
	if self.statesChangedConn then
		self.statesChangedConn:Disconnect()
		self.statesChangedConn = nil
	end
end

return DialogueConceptTrigger