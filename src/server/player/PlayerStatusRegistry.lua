--!strict

local Players = game:GetService("Players")
local PlayerStatusHolder = require(script.Parent.PlayerStatusHolder)

--[=[
	@class PlayerStatusRegistry
]=]
local PlayerStatusRegistry = {}
local playersStatusObjects: { [number]: PlayerStatusHolder.PlayerStatusHolder } = {}

Players.PlayerAdded:Connect(function(player)
	playersStatusObjects[player.UserId] = PlayerStatusHolder.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playersStatusObjects[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playersStatusObjects[player.UserId] then
		playersStatusObjects[player.UserId] = PlayerStatusHolder.new(player)
	end
end

function PlayerStatusRegistry.playerHasStatuses(player: Player): boolean
	if not player then
		return false
	end

	return playersStatusObjects[player.UserId] ~= nil
end

function PlayerStatusRegistry.getPlayerStatusHolder(player: Player): PlayerStatusHolder.PlayerStatusHolder
	return playersStatusObjects[player.UserId]
end

return PlayerStatusRegistry