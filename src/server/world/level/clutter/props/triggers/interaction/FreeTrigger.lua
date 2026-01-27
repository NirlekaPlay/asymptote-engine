--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)
local UString = require(ReplicatedStorage.shared.util.string.UString)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

--[=[
	@class FreeTrigger

	FreeTriggers are buttons that can be placed aroud the world and set various variables.
]=]
local FreeTrigger = {}
FreeTrigger.__index = FreeTrigger

export type FreeTrigger = Prop.Prop & typeof(setmetatable({} :: {
	prompt: WorldInteractionPrompt.WorldInteractionPrompt
}, FreeTrigger))

function FreeTrigger.new(
	prompt: WorldInteractionPrompt.WorldInteractionPrompt
): FreeTrigger
	return setmetatable({
		prompt = prompt
	}, FreeTrigger) :: FreeTrigger
end

function FreeTrigger.createFromPlaceholder(
	placeholder: BasePart, model: Model?, serverLevel: ServerLevel.ServerLevel
): FreeTrigger

	local omniDir = placeholder:GetAttribute("OmniDir") :: boolean?
	local disabledSubtitle = placeholder:GetAttribute("DisabledSubtitle") :: string?
	local disabldTitle = placeholder:GetAttribute("DisabledTitle") :: string?
	local holdAlert = placeholder:GetAttribute("HoldAlert") :: string?
	local holdTime = placeholder:GetAttribute("HoldTime") :: number?
	local serverEnabled = placeholder:GetAttribute("ServerEnabled") :: string?
	local serverVisible = placeholder:GetAttribute("ServerVisible") :: string?
	local tag = placeholder:GetAttribute("Tag") :: string?
	local subtitleKey = placeholder:GetAttribute("SubtitleKey") :: string?
	local titleKey = placeholder:GetAttribute("TitleKey") :: string?
	local clientVisible = placeholder:GetAttribute("ClientVisible") :: string?

	FreeTrigger.makePartStatic(placeholder)

	local builder = InteractionPromptBuilder.new()
		:withPrimaryInteractionKey()
	
	if omniDir ~= nil then
		builder:withOmniDir(omniDir)
	end
	
	if disabledSubtitle ~= nil and not UString.isBlank(disabledSubtitle) then
		builder:withDisabledSubtitleExpr(disabledSubtitle)
	end

	if holdAlert ~= nil and not UString.isBlank(holdAlert) then
		builder:withHoldStatus(holdAlert)
	end

	if holdTime then
		builder:withHoldDuration(holdTime)
	end

	if serverEnabled ~= nil and not UString.isBlank(serverEnabled) then
		builder:withServerEnabledExpression(serverEnabled)
	end

	if serverVisible ~= nil and not UString.isBlank(serverVisible) then
		builder:withServerVisibleExpression(serverVisible)
	end

	if tag ~= nil and not UString.isBlank(tag) then
		builder:withTag(tag)
	end

	if subtitleKey ~= nil then
		builder:withSubtitleKey(subtitleKey)
	end

	if titleKey ~= nil and not UString.isBlank(titleKey) then
		builder:withTitleKey(titleKey)
	end

	if clientVisible ~= nil and not UString.isBlank(clientVisible) then
		builder:withClientVisibleExpression(clientVisible)
	end

	if disabldTitle ~= nil and not UString.isBlank(disabldTitle) then
		builder:withDisabledTitleKey(disabldTitle)
	end

	local prompt = builder:create(placeholder, serverLevel:getExpressionContext())

	local setVariable = placeholder:GetAttribute("SetVariable") :: string?

	if setVariable ~= nil and not UString.isBlank(setVariable) then
		local setValue = placeholder:GetAttribute("SetValue") :: string? or `true`
		
		local parsedSetVariableExpr = ExpressionParser.fromString(setVariable):parse() :: ExpressionParser.ASTNode
		local setVariableUsedVars = ExpressionParser.getVariablesSet(parsedSetVariableExpr)
	
		local parsedSetValueExpr = ExpressionParser.fromString(setValue):parse() :: ExpressionParser.ASTNode
		local setValueUsedVars = ExpressionParser.getVariablesSet(parsedSetVariableExpr)

		local setValueTo: string = ExpressionParser.evaluate(parsedSetValueExpr, serverLevel:getExpressionContext())
		local setVariableTo: string = ExpressionParser.evaluate(parsedSetVariableExpr, serverLevel:getExpressionContext())

		local _statesChangedConn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(variableName, variableValue)
			if setVariableUsedVars[variableName] then
				setVariableTo = ExpressionParser.evaluate(parsedSetVariableExpr, serverLevel:getExpressionContext())
			end

			if setValueUsedVars[variableName] then
				setValueTo = ExpressionParser.evaluate(parsedSetValueExpr, serverLevel:getExpressionContext())
			end
		end)

		local _triggerConn = prompt:getTriggeredEvent():Connect(function(player)
			GlobalStatesHolder.setState(setVariableTo, setValueTo)
		end)
	end

	return FreeTrigger.new(
		prompt
	)
end

function FreeTrigger.update(self: FreeTrigger, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
end

function FreeTrigger.onLevelRestart(self: FreeTrigger): ()
	return
end

--

function FreeTrigger.makePartStatic(part: BasePart): ()
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.AudioCanCollide = false
end

return FreeTrigger