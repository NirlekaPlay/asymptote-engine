--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

--[=[
	@class SensorType

	Defines an interface for an abstract Sensor.
]=]
export type Sensor<T> = {
	requires: (Sensor<T>) -> { MemoryModuleTypes.MemoryModuleType<any> },
	update: (Sensor<T>, agent: T, deltaTime: number) -> (),
	doUpdate: (Sensor<T>, agent: T, deltaTime: number) -> (),
}

return nil