--!nonstrict

local HearingPlayersSensor = require(script.Parent.HearingPlayersSensor)
local SensorType = require(script.Parent.SensorType)
local VisiblePlayersSensor = require(script.Parent.VisiblePlayersSensor)
local PlacedC4Sensor = require(script.Parent.PlacedC4Sensor)

return {
	VISIBLE_PLAYERS_SENSOR = SensorType.new(VisiblePlayersSensor.new),
	HEARING_PLAYERS_SENSOR = SensorType.new(HearingPlayersSensor.new),
	VISIBLE_C4_SENSOR = SensorType.new(PlacedC4Sensor.new)
}