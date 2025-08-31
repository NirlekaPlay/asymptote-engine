--!strict

local Sensor = require(script.Parent.Sensor)
local SensorWrapper = require(script.Parent.SensorWrapper)

local SensorType = {}
SensorType.__index = SensorType

export type SensorType<T> = typeof(setmetatable({} :: {
	create: () -> Sensor.Sensor<T>
}, SensorType))

function SensorType.new(sensorConstructor: () -> Sensor.Sensor<any>): SensorType<any>
	return setmetatable({
		create = function()
			return SensorWrapper.new(sensorConstructor())
		end
	}, SensorType)
end

return SensorType