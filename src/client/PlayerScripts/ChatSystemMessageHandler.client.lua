--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local textChannelsFolder = TextChatService:WaitForChild("TextChannels")
local targetTextChannel = textChannelsFolder:WaitForChild("RBXSystem") :: TextChannel

local function displaySystemMessage(str: string, metadata: string?): ()
	targetTextChannel:DisplaySystemMessage(str, metadata)
end

TypedRemotes.ClientBoundChatMessage.OnClientEvent:Connect(function(payload)
	displaySystemMessage(MutableTextComponent.deserialize(payload.content):buildRichTextMarkupString())
end)