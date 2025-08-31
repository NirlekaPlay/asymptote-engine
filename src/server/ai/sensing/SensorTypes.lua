--!nonstrict

local HearingPlayersSensor = require(script.Parent.HearingPlayersSensor)
local SensorType = require(script.Parent.SensorType)
local VisiblePlayersSensor = require(script.Parent.VisiblePlayersSensor)

return {
	VISIBLE_PLAYERS_SENSOR = SensorType.new(VisiblePlayersSensor.new),
	HEARING_PLAYERS_SENSOR = SensorType.new(HearingPlayersSensor.new)
}