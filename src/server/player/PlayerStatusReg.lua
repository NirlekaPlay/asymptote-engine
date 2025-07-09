--!strict

local Players = game:GetService("Players")
local SuspiciousLevel = require("./SuspiciousLevel")

local playerSusLevel: { [Player]: SuspiciousLevel.SuspiciousLevel } = {}

local PlayerStatusReg = {}

function PlayerStatusReg.getSuspiciousLevel(player: Player): SuspiciousLevel.SuspiciousLevel?
	--print(playerSusLevel)
	--print("attempt to fetch level from", player)
	return playerSusLevel[player]
end

Players.PlayerAdded:Connect(function(player)
	playerSusLevel[player] = SuspiciousLevel.new()
end)

Players.PlayerRemoving:Connect(function(player)
	playerSusLevel[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playerSusLevel[player] then
		playerSusLevel[player] = SuspiciousLevel.new()
	end
end

return PlayerStatusReg