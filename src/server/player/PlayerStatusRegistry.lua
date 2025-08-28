--!strict

local Players = game:GetService("Players")
local PlayerStatus = require("./PlayerStatus")

--[=[
	@class PlayerStatusRegistry
]=]
local PlayerStatusRegistry = {}
local playersStatusObjects: { [number]: PlayerStatus.PlayerStatus} = {}

Players.PlayerAdded:Connect(function(player)
	playersStatusObjects[player.UserId] = PlayerStatus.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playersStatusObjects[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playersStatusObjects[player.UserId] then
		playersStatusObjects[player.UserId] = PlayerStatus.new(player)
	end
end

function PlayerStatusRegistry.playerHasStatuses(player: Player): boolean
	if not player then
		return false
	end

	return playersStatusObjects[player.UserId] ~= nil
end

function PlayerStatusRegistry.getPlayerStatuses(player: Player): PlayerStatus.PlayerStatus
	return playersStatusObjects[player.UserId]
end

return PlayerStatusRegistry