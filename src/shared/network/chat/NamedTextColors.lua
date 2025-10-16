--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)

return {
	RED = TextColor.new(0xF74B52),
	YELLOW = TextColor.new(16777045),
	DARK_AQUA = TextColor.new(43690),
	MUTED_SOFT_AQUA = TextColor.new(0x80C0C0),
	MUTED_LIGHT_BLUE = TextColor.new(0xA0CFFF),
	SOFT_YELLOW = TextColor.new(0xFFD966),
	LIGHT_GRAY = TextColor.new(0xD0D0D0),
	WHITE = TextColor.new(0xFFFFFF),
	CREAM = TextColor.new(0xE0E0C0),
}