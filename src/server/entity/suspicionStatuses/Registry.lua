--!strict
local Status = require(script.Parent.Status)
local Types = require(script.Parent.Types)

return {
	DISGUISED = Status.new("DISGUISED", 1, true, -37.5),
	MINOR_TRESPASSING = Status.new("MINOR_TRESPASSING", 2, false, 0),
	MINOR_SUSPICIOUS = Status.new("MINOR_SUSPICIOUS", 3, true, 0),
	MAJOR_TRESPASSING = Status.new("MAJOR_TRESPASSING", 4, false, 25),
	CRIMINAL_SUSPICIOUS = Status.new("CRIMINAL_SUSPICIOUS", 5, true, 25),
	DANGEROUS_ITEM = Status.new("DANGEROUS_ITEM", 6, true, 50),
	ARMED = Status.new("ARMED", 7, true, 50),

} :: { [string]: Types.Status }