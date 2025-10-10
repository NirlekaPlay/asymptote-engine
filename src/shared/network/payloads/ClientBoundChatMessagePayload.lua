--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

export type ClientBoundChatMessagePayload = {
	content: MutableTextComponent.SerializedComponentResult
}

return nil