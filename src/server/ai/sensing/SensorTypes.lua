--!nonstrict

local SensorType = require(script.Parent.SensorType)
local VisiblePlayersSensor = require(script.Parent.VisiblePlayersSensor)

return {
	VISIBLE_PLAYERS_SENSOR = SensorType.new(VisiblePlayersSensor.new)
}