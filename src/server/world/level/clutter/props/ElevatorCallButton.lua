--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UString = require(ReplicatedStorage.shared.util.string.UString)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

--[=[
	@class ElevatorCallButton
]=]
local ElevatorCallButton = {}
ElevatorCallButton.__index = ElevatorCallButton

export type ElevatorCallButton = Prop.Prop & typeof(setmetatable({} :: {
	proxPromptTriggeredConn: RBXScriptConnection
}, ElevatorCallButton))

function ElevatorCallButton.createFromPlaceholder(
	placeholder: BasePart,
	model: Model,
	serverLevel: ServerLevel.ServerLevel
): ElevatorCallButton

	local requestVariableName = placeholder:GetAttribute("RequestVariable") :: string?
	if not requestVariableName then
		error(`ERR_NO_REQUEST_VAR`) -- Too lazy.
	end

	local targetElevId = placeholder:GetAttribute("TargetElevId") :: string?
	if not targetElevId then
		error(`ERR_NO_TARGET_ELEV_ID`)
	end

	local active = placeholder:GetAttribute("Active") :: string?

	local buttonPart = (model :: any).Button :: BasePart

	local builder = InteractionPromptBuilder.new()
		:withPrimaryInteractionKey()
		:withOmniDir(false)
		:withTitleKey("ui.prompt.call")
		:withSubtitleKey("object.generic.elevator")
		:withWorldOffsetBy(0.11)

	if active ~= nil and not UString.isBlank(active) then
		builder:withServerEnabledExpression(active)
		builder:withDisabledSubtitleExpr(`'ui.prompt.cant_request_elev'`)
	end
	
	local prompt= builder:create(buttonPart, serverLevel:getExpressionContext())

	local triggeredConn = prompt:getTriggeredEvent():Connect(function()
		GlobalStatesHolder.setState(requestVariableName, targetElevId)
	end)

	return setmetatable({
		proxPromptTriggeredConn = triggeredConn
	}, ElevatorCallButton) :: ElevatorCallButton
end

function ElevatorCallButton.update(self: ElevatorCallButton, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
	return
end

function ElevatorCallButton.onLevelRestart(self: ElevatorCallButton, serverLevel: ServerLevel.ServerLevel): ()
	return
end

return ElevatorCallButton