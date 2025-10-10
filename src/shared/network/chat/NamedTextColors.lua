--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)

return {
	RED = TextColor.new(0xF74B52)
}