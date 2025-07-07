--!strict
local Statuses = require(script.Parent.Statuses)

-- kill me.

local playerStatuses: { [Player]: { [Statuses.PlayerStatus]: true }} = {}

local PlayerStatusReg = {}

function PlayerStatusReg.setStatus(player: Player, statusType: Statuses.PlayerStatus, value: boolean): ()
	local plrStatuses = playerStatuses[player]
	if not plrStatuses then
		playerStatuses[player] = {}
	end

	if value then
		plrStatuses[statusType] = true
	else
		plrStatuses[statusType] = nil
	end

	print(playerStatuses)
end

return PlayerStatusReg