--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

--[=[
	@class Sensor

	Defines the interface of a Sensor instance.
]=]
export type Sensor<T> = {
	getRequiredMemories: ( self: Sensor<T> ) -> { MemoryModuleTypes.MemoryModuleType<any> },
	getScanRate: ( self: Sensor<T> ) -> number,
	doUpdate: ( self: Sensor<T> , agent: T, deltaTime: number) -> (),
}

return nil