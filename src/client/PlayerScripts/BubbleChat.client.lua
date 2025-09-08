local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TypedBubbleChatRemote = require(ReplicatedStorage.shared.network.remotes.TypedRemotes).BubbleChat

TypedBubbleChatRemote.OnClientEvent:Connect(function(part, text)
	TextChatService:DisplayBubble(part, text)
end)