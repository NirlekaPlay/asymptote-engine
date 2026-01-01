--!strict

local ServerScriptService = game:GetService("ServerScriptService")
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

	local buttonPart = (model :: any).Button :: BasePart

	local triggerAttachment = Instance.new("Attachment")
	triggerAttachment.Name = "Trigger"
	triggerAttachment.Parent = buttonPart

	local halfSize = buttonPart.Size.X / 2
	local dist = 0.2
	triggerAttachment.CFrame = CFrame.new(-(halfSize + dist), 0, 0) * CFrame.lookAt(Vector3.zero, -Vector3.new(1, 0, 0))

	local proxPrompt = Instance.new("ProximityPrompt")
	proxPrompt.ActionText = "ui.prompt.call" -- TODO: Localization
	proxPrompt.ObjectText = "object.generic.elevator"
	proxPrompt.HoldDuration = 0.3
	proxPrompt.MaxActivationDistance = 5
	proxPrompt.Style = Enum.ProximityPromptStyle.Custom
	proxPrompt.Parent = triggerAttachment

	local triggeredConn = proxPrompt.Triggered:Connect(function()
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