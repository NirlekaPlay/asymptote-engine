--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Optional = require(ServerScriptService.server.ai.memory.Optional)
local Sensor = require(ServerScriptService.server.ai.sensing.Sensor)
local SensorType = require(ServerScriptService.server.ai.sensing.SensorType)

local Brain = {}
Brain.__index = Brain

type self<T> = {
	agent: T,
	memories: { [MemoryModuleType<any>]: Optional<ExpireableValue<any>> },
	sensors: { [SensorType<any>]: Sensor<any> },
	activities: {},
	behaviours: {}
}

export type Brain<T> = typeof(setmetatable({} :: self<T>, Brain))

type Optional<T> = Optional.Optional<T>
type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type ExpireableValue<T> = ExpireableValue.ExpireableValue<T>
type SensorType<T> = SensorType.SensorType<T>
type Sensor<T> = Sensor.Sensor<T>
type MemoryStatus = MemoryStatus.MemoryStatus

function Brain.new<T>(agent: T, sensors: { SensorType<any> } ): Brain<T>
	local self = {} :: self<T>

	self.activities = {}
	self.agent = agent
	self.behaviours = {}
	self.memories = {}
	self.sensors = {}

	for _, sensorType in ipairs(sensors) do
		self.sensors[sensorType] = sensorType.create()
	end

	for _, sensor in pairs(self.sensors) do
		for _, memoryModuleType in ipairs(sensor:requires()) do
			self.memories[memoryModuleType] = Optional.empty()
		end
	end

	return setmetatable(self, Brain)
end

local function isEmptyTable(t: { [any]: any }): boolean
	if type(t) ~= "table" then
		return false
	end

	return next(t) == nil
end

function Brain.getMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): Optional<ExpireableValue<U>>
	local optional = self.memories[memoryType]
	if (optional :: any) == nil then
		error(`Attempt to fetch non-registered {memoryType.name} memory`)
	else
		return optional
	end
end

function Brain.hasMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): boolean
	return self.memories[memoryType] ~= nil
end

function Brain.hasMemoryValue<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): boolean
	return self:checkMemory(memoryType, MemoryStatus.VALUE_PRESENT)
end

function Brain.checkMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, status: MemoryStatus): boolean
	local optional = self.memories[memoryType]

	if (optional :: any) == nil then
		return false
	end

	return status == MemoryStatus.REGISTERED
		or (status == MemoryStatus.VALUE_PRESENT and optional:isPresent())
		or (status == MemoryStatus.VALUE_ABSENT and not optional:isPresent())
end

function Brain.eraseMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): ()
	self:setMemoryInternal(memoryType, Optional.empty())
end

function Brain.setNullableMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, memoryValue: U?): ()
	self:setMemoryInternal(memoryType, Optional.ofNullable(memoryValue):map(ExpireableValue.nonExpiring))
end

function Brain.setMemoryWithExpiry<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, memoryValue: U, ttl: number): ()
	self:setMemoryInternal(memoryType, Optional.of(ExpireableValue.new(memoryValue, ttl)))
end

function Brain.setMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, optional: Optional<U>): ()
	self:setMemoryInternal(memoryType, optional:map(ExpireableValue.nonExpiring))
end

function Brain.setMemoryInternal<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, optional: Optional<ExpireableValue<U?>>): ()
	if self.memories[memoryType] then
		if optional:isPresent() and isEmptyTable(optional:get():getValue()) then
			self:eraseMemory(memoryType)
		else
			self.memories[memoryType] = optional
		end
	end
end

function Brain.update<T>(self: Brain<T>, deltaTime: number): ()
	self:updateSensors(deltaTime)
end

function Brain.updateSensors<T>(self: Brain<T>, deltaTime: number): ()
	for _, sensor in pairs(self.sensors) do
		sensor:update(self.agent, deltaTime)
	end
end

return Brain