--!strict

local PlayerStatus = require(script.Parent.PlayerStatus)

return {
	DISGUISED = PlayerStatus.new("DISGUISED", 1, true, -37.5),
	MINOR_TRESPASSING = PlayerStatus.new("MINOR_TRESPASSING", 1, false, 0),
	MINOR_SUSPICIOUS = PlayerStatus.new("MINOR_SUSPICIOUS", 1, true, 0),
	MAJOR_TRESPASSING = PlayerStatus.new("MAJOR_TRESPASSING", 1, false, 25),
	CRIMINAL_SUSPICIOUS = PlayerStatus.new("CRIMINAL_SUSPICIOUS", 1, true, 25),
	DANGEROUS_ITEM = PlayerStatus.new("DANGEROUS_ITEM", 1, true, 50),
	ARMED = PlayerStatus.new("ARMED", 1, true, 50),
}