--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

--[=[
	Defines the sensot interfaces that directly interacts within the Brain
	update cycle.
]=]
export type SensorControl<T> = {
	getRequiredMemories: (self: SensorControl<T>) -> { MemoryModuleTypes.MemoryModuleType<any> },
	update: (self: SensorControl<T>, agent: T, deltaTime: number) -> ()
}

return nil