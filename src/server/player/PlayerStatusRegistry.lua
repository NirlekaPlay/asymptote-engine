--!strict

local Players = game:GetService("Players")
local PlayerStatus = require("./PlayerStatus")

--[=[
	@class PlayerStatusRegistry
]=]
local PlayerStatusRegistry = {}
local playersStatusObjects: { [Player]: PlayerStatus.PlayerStatus} = {}

Players.PlayerAdded:Connect(function(player)
	playersStatusObjects[player] = PlayerStatus.new()
end)

Players.PlayerRemoving:Connect(function(player)
	playersStatusObjects[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playersStatusObjects[player] then
		playersStatusObjects[player] = PlayerStatus.new()
	end
end

function PlayerStatusRegistry.getPlayerStatuses(player: Player): PlayerStatus.PlayerStatus
	return playersStatusObjects[player]
end

return PlayerStatusRegistry