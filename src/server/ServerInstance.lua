--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverTeleData: any = nil

--[=[
	@class Server
]=]
local Server = {}

--[=[
	Returns `true` if the server is a private server. This can be any servers that is not
	open for all players, and is only created when a player creates a lobby to join a mission.<p>
]=]
function Server.isServerPrivate(): boolean
	local isPrivateBoolValue = ReplicatedStorage:FindFirstChild("IsPrivate")
	if isPrivateBoolValue and isPrivateBoolValue:IsA("BoolValue") then
		return isPrivateBoolValue.Value
	end

	return false
end

function Server.setTeleData(data: any): ()
	serverTeleData = data
end

function Server.getTeleData(): any
	return serverTeleData
end

return Server