--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedBubbleChatRemote = require(ReplicatedStorage.shared.network.TypedBubbleChatRemote)

--[=[
	@class BubbleChatControl

	Controls the display of bubble chat to clients.
]=]
local BubbleChatControl = {}
BubbleChatControl.__index = BubbleChatControl

export type BubbleChatControl = typeof(setmetatable({} :: {
	character: Model
}, BubbleChatControl))

function BubbleChatControl.new(character: Model): BubbleChatControl
	return setmetatable({
		character = character
	}, BubbleChatControl)
end

function BubbleChatControl.displayBubble(self: BubbleChatControl, text: string): ()
	TypedBubbleChatRemote:FireAllClients(self.character.PrimaryPart, text)
end

return BubbleChatControl