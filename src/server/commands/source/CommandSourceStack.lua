--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)
local CommandSource = require(ServerScriptService.server.commands.source.CommandSource)

local FORMATTING_STYLES = {
	RED = TextStyle.empty()
		:withColor(NamedTextColors.RED)
}

--[=[
	@class CommandSourceStack
]=]
local CommandSourceStack = {}
CommandSourceStack.__index = CommandSourceStack

export type CommandSourceStack = typeof(setmetatable({} :: {
	source: CommandSource.CommandSource,
	entity: Instance,
	position: Vector3,
	displayName: string,
	textName: string
}, CommandSourceStack))

function CommandSourceStack.new(
	source: CommandSource.CommandSource,
	entity: Instance,
	position: Vector3,
	displayName: string,
	textName: string
): CommandSourceStack
	return setmetatable({
		source = source,
		entity = entity,
		position = position,
		displayName = displayName,
		textName = textName
	}, CommandSourceStack)
end

function CommandSourceStack.getPlayerOrThrow(self: CommandSourceStack): Player
	if self.entity:IsA("Player") then
		return self.entity
	else
		error("CommandSourceStack.getPlayerOrThrow() failure: Entity is not of type Player.")
	end
end

function CommandSourceStack.sendSuccess(
	self: CommandSourceStack,
	component: MutableTextComponent.MutableTextComponent
): ()
	self.source:sendSystemMessage(component)
end

function CommandSourceStack.sendFailure(
	self: CommandSourceStack,
	component: MutableTextComponent.MutableTextComponent
): ()
	self.source:sendSystemMessage(
		MutableTextComponent.literal("")
			:appendComponent(component)
			:withStyle(FORMATTING_STYLES.RED))
end

return CommandSourceStack