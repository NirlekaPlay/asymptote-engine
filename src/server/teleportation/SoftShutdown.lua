--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local ServerInstance = require(ServerScriptService.server.ServerInstance)
local Teleportation = require(ServerScriptService.server.teleportation.Teleportation)

local MSG_TELEPORTING = "Rebooting servers for update. Please wait..."

--[=[
	@class SoftShutdown
]=]
local SoftShutdown = {}

--[=[
	Utility method to automatically handle soft shutdown.
]=]
function SoftShutdown.shutdown(): ()
	if ServerInstance.isServerPrivate() then
		SoftShutdown.softShutdownCurrentPrivateServer()
	end
end

--[=[
	Use this to soft shutdown a reserved server or a private server.
	Since these don't use Roblox's general servers, you can just teleport them to a new place.<p>
	Should only be called once.
]=]
function SoftShutdown.softShutdownCurrentPrivateServer(): ()
	SoftShutdown._createMessage(MSG_TELEPORTING)

	local data = ServerInstance.getTeleData()
	local accessCode = Teleportation.createReservedSession(nil, game.PlaceId, data)

	TeleportService:TeleportToPrivateServer(game.PlaceId, accessCode, Players:GetPlayers())

	Players.PlayerAdded:Connect(function(player)
		TeleportService:TeleportToPrivateServer(game.PlaceId, accessCode, {player})
	end)
end

--

function SoftShutdown._createMessage(msg: string): ()
	local m = Instance.new("Message")
	m.Text = msg
	m.Parent = workspace
end

return SoftShutdown