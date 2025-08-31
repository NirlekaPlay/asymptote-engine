--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedBubbleChatRemote = require(ReplicatedStorage.shared.network.TypedRemotes).BubbleChat

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
	if not self:isAgentValid() then
		return
	end

	TypedBubbleChatRemote:FireAllClients(self.character.PrimaryPart, text)
end

function BubbleChatControl.isAgentValid(self: BubbleChatControl): boolean
	local character = self.character
	if not character or not character:IsDescendantOf(workspace) then
		return false
	end

	if not character.PrimaryPart then
		return false
	end

	return true
end

return BubbleChatControl