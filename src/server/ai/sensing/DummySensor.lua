--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local DummySensor = {}
DummySensor.__index = DummySensor

export type DummySensor = typeof(setmetatable({} :: {
	_timeAccumulator: number,
}, DummySensor))

function DummySensor.new(): DummySensor
	return setmetatable({
		_timeAccumulator = 0
	}, DummySensor)
end

function DummySensor.requires(self: DummySensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.VISIBLE_PLAYERS }
end

function DummySensor.update(self: DummySensor, agent, deltaTime: number): ()
	self._timeAccumulator += deltaTime

	if self._timeAccumulator >= 1 then
		self._timeAccumulator = 0
		self:doUpdate(agent, deltaTime)
	end
end

function DummySensor.doUpdate(self: DummySensor, agent, deltaTime: number)
	print("Hello, world! From DummySensor.doUpdate!")
end

return DummySensor