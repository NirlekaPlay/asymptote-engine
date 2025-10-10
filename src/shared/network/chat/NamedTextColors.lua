--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)

return {
	RED = TextColor.new(0xF74B52),
	YELLOW = TextColor.new(16777045),
	DARK_AQUA = TextColor.new(43690)
}