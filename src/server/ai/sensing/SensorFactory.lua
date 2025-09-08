--!strict

local Sensor = require(script.Parent.Sensor)
local SensorControl = require(script.Parent.SensorControl)
local SensorWrapper = require(script.Parent.SensorWrapper)

local SensorFactory = {}
SensorFactory.__index = SensorFactory

export type SensorFactory<T> = typeof(setmetatable({} :: {
	create: () -> SensorControl.SensorControl<T>
}, SensorFactory))

function SensorFactory.new(sensorConstructor: () -> Sensor.Sensor<any>): SensorFactory<any>
	return setmetatable({
		create = function()
			return SensorWrapper.new(sensorConstructor()) :: SensorControl.SensorControl<any>
		end
	}, SensorFactory)
end

return SensorFactory