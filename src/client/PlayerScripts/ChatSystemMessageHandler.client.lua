--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local RBXGeneral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel

local HEX_WHITE = "#ffffff"
local HEX_RED = "#F52727"
local DEFAULT_TEXT_COLOR = HEX_WHITE

local function escapeHtml(str: string): string
	return (str :: any):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function displaySystemMessage(str: string, color: string?): ()
	color = color or DEFAULT_TEXT_COLOR
	
	for line in str:gmatch("([^\n]+)") do
		if color == DEFAULT_TEXT_COLOR then
			RBXGeneral:DisplaySystemMessage(line)
		else
			local escapedLine = escapeHtml(line)
			local formattedLine = string.format('<font color="%s">%s</font>', color, escapedLine)
			RBXGeneral:DisplaySystemMessage(formattedLine)
		end
	end
end

TypedRemotes.ClientBoundChatMessage.OnClientEvent:Connect(function(payload)
	local color: string?
	if payload.type == "plain" then
		color = HEX_WHITE
	elseif payload.type == "error" then
		color = HEX_RED
	end
	displaySystemMessage(payload.literalString, color)
end)