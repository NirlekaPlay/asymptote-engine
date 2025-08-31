--!strict

local PlayerStatus = require(script.Parent.PlayerStatus)

return {
	DISGUISED = PlayerStatus.new("DISGUISED", 1, true, -37.5),
	MINOR_TRESPASSING = PlayerStatus.new("MINOR_TRESPASSING", 2, false, 0),
	MINOR_SUSPICIOUS = PlayerStatus.new("MINOR_SUSPICIOUS", 3, true, 0),
	MAJOR_TRESPASSING = PlayerStatus.new("MAJOR_TRESPASSING", 4, false, 25),
	CRIMINAL_SUSPICIOUS = PlayerStatus.new("CRIMINAL_SUSPICIOUS", 5, true, 25),
	DANGEROUS_ITEM = PlayerStatus.new("DANGEROUS_ITEM", 6, true, 50),
	ARMED = PlayerStatus.new("ARMED", 7, true, 50),
}