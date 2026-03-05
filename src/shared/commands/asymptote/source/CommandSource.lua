--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

export type CommandSource = {
	sendSystemMessage: (self: CommandSource, component: MutableTextComponent.MutableTextComponent) -> ()
}

return nil