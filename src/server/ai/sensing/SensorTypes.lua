--!nonstrict

local HearingPlayersSensor = require(script.Parent.HearingPlayersSensor)
local PlacedC4Sensor = require(script.Parent.PlacedC4Sensor)
local SensorType = require(script.Parent.SensorType)
local VisibleEntitiesSensor = require(script.Parent.VisibleEntitiesSensor)
local VisiblePlayersSensor = require(script.Parent.VisiblePlayersSensor)

return {
	VISIBLE_ENTITIES_SENSOR = SensorType.new(VisibleEntitiesSensor.new),
	VISIBLE_PLAYERS_SENSOR = SensorType.new(VisiblePlayersSensor.new),
	HEARING_PLAYERS_SENSOR = SensorType.new(HearingPlayersSensor.new),
	VISIBLE_C4_SENSOR = SensorType.new(PlacedC4Sensor.new)
}