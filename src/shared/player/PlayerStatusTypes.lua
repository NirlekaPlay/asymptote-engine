--!strict

local PlayerStatus = require(script.Parent.PlayerStatus)

local PlayerStatusTypes = {
	DISGUISED = PlayerStatus.new("DISGUISED", 2, true, 0.625),
	MINOR_TRESPASSING = PlayerStatus.new("MINOR_TRESPASSING", 4, false, 1),
	MINOR_SUSPICIOUS = PlayerStatus.new("MINOR_SUSPICIOUS", 3, true, 1),
	MAJOR_TRESPASSING = PlayerStatus.new("MAJOR_TRESPASSING", 5, false, 1.25),
	CRIMINAL_SUSPICIOUS = PlayerStatus.new("CRIMINAL_SUSPICIOUS", 6, true, 1.25),
	DANGEROUS_ITEM = PlayerStatus.new("DANGEROUS_ITEM", 8, true, 1),
	-- GunShot - 9
	ARMED = PlayerStatus.new("ARMED", 10, true, 1.5)
}

function PlayerStatusTypes.getStatusFromName(statusName: string): PlayerStatus.PlayerStatus?
	return PlayerStatusTypes[statusName]
end

return PlayerStatusTypes