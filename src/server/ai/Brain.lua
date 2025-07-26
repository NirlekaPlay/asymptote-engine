--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local BehaviorControl = require(ServerScriptService.server.ai.behavior.BehaviorControl)
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
	defaultActivity: Activity,
	memories: { [MemoryModuleType<any>]: Optional<ExpireableValue<any>> },
	sensors: { [SensorType<any>]: Sensor<any> },
	activeActivities: { [Activity]: true },
	availableBehaviorsByPriority: { [number]: { [Activity]: { [BehaviorControl<T>]: true } } }
}

export type Brain<T> = typeof(setmetatable({} :: self<T>, Brain))

type Optional<T> = Optional.Optional<T>
type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type ExpireableValue<T> = ExpireableValue.ExpireableValue<T>
type SensorType<T> = SensorType.SensorType<T>
type Sensor<T> = Sensor.Sensor<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type BehaviorControl<T> = BehaviorControl.BehaviorControl<T>
type Activity = Activity.Activity

function Brain.new<T>(agent: T, memories: { MemoryModuleType<any> }, sensors: { SensorType<T> } ): Brain<T>
	local self = {} :: self<T>

	self.agent = agent
	self.defaultActivity = Activity.IDLE
	self.activeActivities = {}
	self.availableBehaviorsByPriority = {}
	self.memories = {}
	self.sensors = {}

	for _, memoryModuleType in ipairs(memories) do
		self.memories[memoryModuleType] = Optional.empty()
	end

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
		error(`Attempt to fetch unregistered '{memoryType.name}' memory`)
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

function Brain.setDefaultActivity<T>(self: Brain<T>, activity: Activity): ()
	self.defaultActivity = activity
end

function Brain.setActiveActivity<T>(self: Brain<T>, activity: Activity): ()
	if not self:isActivityActive(activity) then
		table.clear(self.activeActivities)
		self.activeActivities[activity] = true
	end
end

function Brain.useDefaultActivity<T>(self: Brain<T>): ()
	self:setActiveActivity(self.defaultActivity)
end

function Brain.addActivity<T>(self: Brain<T>, activity: Activity, priority: number, BehaviorControls: { BehaviorControl<T> }): ()
	local behaviorControlSets: { [BehaviorControl<T>]: true } = {}
	for _, BehaviorControl in ipairs(BehaviorControls) do
		behaviorControlSets[BehaviorControl] = true
	end

	self.availableBehaviorsByPriority[priority] = {
		[activity] = behaviorControlSets
	}
end

function Brain.isActivityActive<T>(self: Brain<T>, activity: Activity): boolean
	return self.activeActivities[activity] ~= nil
end

function Brain.getRunningBehaviors<T>(self: Brain<T>): { BehaviorControl<T> }
	local behaviorControlsArray = {}

	for _, activity in pairs(self.availableBehaviorsByPriority) do
		for _, behaviorControls in pairs(activity) do
			for behaviorControl in pairs(behaviorControlsArray) do
				if behaviorControl:getStatus() ~= BehaviorControl.Status.RUNNING then
					continue
				end

				table.insert(behaviorControlsArray, BehaviorControl)
			end
		end
	end

	return behaviorControlsArray
end

function Brain.update<T>(self: Brain<T>, deltaTime: number): ()
	self:forgetExpiredMemories(deltaTime)
	self:updateSensors(deltaTime)
	self:startEachNonRunningBehavior()
	self:updateEachRunningBehavior()
end

function Brain.updateSensors<T>(self: Brain<T>, deltaTime: number): ()
	for _, sensor in pairs(self.sensors) do
		sensor:update(self.agent, deltaTime)
	end
end

function Brain.forgetExpiredMemories<T>(self: Brain<T>, deltaTime: number): ()
	for memoryType, optional in pairs(self.memories) do
		if not optional:isPresent() then
			continue
		end

		local expireableValue = optional:get()
		if expireableValue:isExpired() then
			self:eraseMemory(memoryType)
		end

		expireableValue:update(deltaTime)
	end
end

function Brain.startEachNonRunningBehavior<T>(self: Brain<T>): ()
	local currentTime = tick()

	for priority, activities in pairs(self.availableBehaviorsByPriority) do
		for activity, behaviorControls in pairs(activities) do
			if not self.activeActivities[activity] then
				continue
			end

			for behaviorControl in pairs(behaviorControls) do
				if behaviorControl:getStatus() ~= BehaviorControl.Status.STOPPED then
					continue
				end

				behaviorControl:tryStart(self.agent, currentTime)
			end
		end
	end
end

function Brain.updateEachRunningBehavior<T>(self: Brain<T>): ()
	local currentTime = tick()

	for _, behaviorControl in ipairs(self:getRunningBehaviors()) do
		behaviorControl:updateOrStop(self.agent, currentTime)
	end
end

return Brain