--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local BulletTracersSensor = require(ServerScriptService.server.ai.sensing.BulletTracersSensor)
local HearingPlayersSensor = require(script.Parent.HearingPlayersSensor)
local PlacedC4Sensor = require(script.Parent.PlacedC4Sensor)
local SensorFactory = require(script.Parent.SensorFactory)
local VisibleEntitiesSensor = require(script.Parent.VisibleEntitiesSensor)
local VisiblePlayersSensor = require(script.Parent.VisiblePlayersSensor)

return {
	VISIBLE_ENTITIES_SENSOR = SensorFactory.new(VisibleEntitiesSensor.new),
	VISIBLE_PLAYERS_SENSOR = SensorFactory.new(VisiblePlayersSensor.new),
	HEARING_PLAYERS_SENSOR = SensorFactory.new(HearingPlayersSensor.new),
	VISIBLE_C4_SENSOR = SensorFactory.new(PlacedC4Sensor.new),
	BULLET_TRACING_SENSOR = SensorFactory.new(function()
		return BulletTracersSensor.new(5)
	end)
}