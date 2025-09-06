--!strict

local Sensor = require(script.Parent.Sensor)
local SensorWrapper = require(script.Parent.SensorWrapper)

local SensorFactory = {}
SensorFactory.__index = SensorFactory

export type SensorFactory<T> = typeof(setmetatable({} :: {
	create: () -> Sensor.Sensor<T>
}, SensorFactory))

function SensorFactory.new(sensorConstructor: () -> Sensor.Sensor<any>): SensorFactory<any>
	return setmetatable({
		create = function()
			return SensorWrapper.new(sensorConstructor())
		end
	}, SensorFactory)
end

return SensorFactory