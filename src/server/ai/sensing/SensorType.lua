--!strict

local Sensor = require(script.Parent.Sensor)

local SensorType = {}
SensorType.__index = SensorType

export type SensorType<T> = typeof(setmetatable({} :: {
	create: () -> Sensor.Sensor<T>
}, SensorType))

function SensorType.new(sensorConstructor: () -> Sensor.Sensor<any>): SensorType<any>
	return setmetatable({
		create = sensorConstructor
	}, SensorType)
end

return SensorType