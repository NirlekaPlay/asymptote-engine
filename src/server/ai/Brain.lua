--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local BehaviorControl = require(ServerScriptService.server.ai.behavior.BehaviorControl)
local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Optional = require(ServerScriptService.server.ai.memory.Optional)
local SensorControl = require(ServerScriptService.server.ai.sensing.SensorControl)
local SensorFactory = require(ServerScriptService.server.ai.sensing.SensorFactory)

local Brain = {}
Brain.__index = Brain

type self<T> = {
	agent: T,
	defaultActivity: Activity,
	memories: { [MemoryModuleType<any>]: Optional<ExpireableValue<any>> },
	sensors: { [SensorFactory<any>]: SensorControl<any> },
	activeActivities: { [Activity]: true },
	activityRequirements: { [Activity]: { [MemoryModuleType<any>]: MemoryStatus } },
	activityMemoriesToEraseWhenStopped: { [Activity]: { [MemoryModuleType<any>]: true } },
	availableBehaviorsByPriority: { [number]: { [Activity]: { [BehaviorControl<T>]: true } } },
	coreActivities: { [Activity]: true }
}

export type Brain<T> = typeof(setmetatable({} :: self<T>, Brain))

type Optional<T> = Optional.Optional<T>
type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type ExpireableValue<T> = ExpireableValue.ExpireableValue<T>
type SensorFactory<T> = SensorFactory.SensorFactory<T>
type SensorControl<T> = SensorControl.SensorControl<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type BehaviorControl<T> = BehaviorControl.BehaviorControl<T>
type Activity = Activity.Activity

function Brain.new<T>(agent: T, memories: { MemoryModuleType<any> }, sensors: { SensorFactory<T> } ): Brain<T>
	local self = {} :: self<T>

	self.agent = agent
	self.defaultActivity = Activity.IDLE
	self.activeActivities = {}
	self.activityMemoriesToEraseWhenStopped = {}
	self.activityRequirements = {}
	self.availableBehaviorsByPriority = {}
	self.coreActivities = {}
	self.memories = {}
	self.sensors = {}

	for _, memoryModuleType in ipairs(memories) do
		self.memories[memoryModuleType] = Optional.empty()
	end

	for _, SensorFactory in ipairs(sensors) do
		self.sensors[SensorFactory] = SensorFactory.create()
	end

	for _, sensor in pairs(self.sensors) do
		for _, memoryModuleType in ipairs(sensor:getRequiredMemories()) do
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

--[=[
	Fetches the Optional associated with the given memory module type.
	Throws an error if the memory module type has not been registered.
	Otherwise, returns an Optional containing the stored value, which
	may be empty if the memory is unset.
]=]
function Brain.getMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): Optional<U>
	local optional = self.memories[memoryType]
	if (optional :: any) == nil then
		error(`Attempt to fetch unregistered '{memoryType.name}' memory`)
	else
		return optional:map(function(expireableValue) 
			return expireableValue:getValue()
		end)
	end
end

--[=[
	Returns whether the memory associated with the given MemoryModuleType
	has a stored value.

	Each registered memory module always has an Optional container but the
	Optional may be empty if no value has been set. This function returns
	true only when the Optional is populated; otherwise, it returns false.

	Unregistered memory types will always return false.
]=]
function Brain.hasMemoryValue<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): boolean
	return self:checkMemory(memoryType, MemoryStatus.VALUE_PRESENT)
end

--[=[
	Checks the state of the memory associated with the given MemoryModuleType
	against the provided MemoryStatus.

	The `MemoryStatus` determines what this function tests for:

	- `MemoryStatus.REGISTERED`:  
	  Returns true if the given memory type has been registered, regardless of
	  whether it currently has a value.
	- `MemoryStatus.VALUE_PRESENT`:  
	  Returns true only if the memory type is registered **and** its Optional
	  currently contains a value.
	- `MemoryStatus.VALUE_ABSENT`:  
	  Returns true only if the memory type is registered **and** its Optional
	  is empty.

	If the memory type has never been registered, the function always returns false
	for `VALUE_PRESENT` and `VALUE_ABSENT`, but returns false for `REGISTERED` only
	if the Optional itself is missing entirely.
]=]
function Brain.checkMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, status: MemoryStatus): boolean
	local optional = self.memories[memoryType]

	if (optional :: any) == nil then
		return false
	end

	return status == MemoryStatus.REGISTERED
		or (status == MemoryStatus.VALUE_PRESENT and optional:isPresent())
		or (status == MemoryStatus.VALUE_ABSENT and not optional:isPresent())
end

--[=[
	Clears the value associated with the given MemoryModuleType.

	This replaces the existing Optional for the given memory type with an
	empty Optional, effectively "forgetting" any previously stored value.
]=]
function Brain.eraseMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>): ()
	self:setMemoryInternal(memoryType, Optional.empty() :: any) -- shut up.
end

--[=[
	Sets the memory value for the given MemoryModuleType, accepting a value
	that can be nil.

	* If `memoryValue` is not nil, it is wrapped in a non-expiring ExpireableValue.
	* If `memoryValue` is nil, the memory is effectively erased by storing an empty Optional.
]=]
function Brain.setNullableMemory<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, memoryValue: U?): ()
	self:setMemoryInternal(memoryType, Optional.ofNullable(memoryValue):map(ExpireableValue.nonExpiring))
end

--[=[
	Sets the memory value for the given MemoryModuleType with a time-to-live (TTL)

	The value is wrapped in an ExpireableValue that automatically expires
	after the given number of seconds. Once expired, the memory is set to an
	empty Optional, effectiely erasing it.
]=]
function Brain.setMemoryWithExpiry<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, memoryValue: U, ttl: number): ()
	self:setMemoryInternal(memoryType, Optional.of(ExpireableValue.new(memoryValue, ttl)))
end

function Brain.setMemoryInternal<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, optional: Optional<ExpireableValue<U>>): ()
	if self.memories[memoryType] then
		if optional:isPresent() and isEmptyTable(optional:get():getValue()) then
			self:eraseMemory(memoryType)
		else
			self.memories[memoryType] = optional
		end
	end
end

--

function Brain.setCoreActivities<T>(self: Brain<T>, activities: { Activity }): ()
	local coreActivitiesSet = {}
	for _, activity in ipairs(activities) do
		coreActivitiesSet[activity] = true
	end

	self.coreActivities = coreActivitiesSet
end

function Brain.setDefaultActivity<T>(self: Brain<T>, activity: Activity): ()
	self.defaultActivity = activity
end

function Brain.setActiveActivity<T>(self: Brain<T>, activity: Activity): ()
	if not self:isActivityActive(activity) then
		self:eraseMemoriesForOtherActivitiesThan(activity)
		table.clear(self.activeActivities)
		for activity in pairs(self.coreActivities) do
			self.activeActivities[activity] = true
		end
		self.activeActivities[activity] = true
	end
end

function Brain.setActiveActivityToFirstValid<T>(self: Brain<T>, activities: {Activity}): ()
	for _, activity in ipairs(activities) do
		if self:activityRequirementsAreMet(activity) then
			self:setActiveActivity(activity)
			break
		end
	end
end

function Brain.activityRequirementsAreMet<T>(self: Brain<T>, activity: Activity): boolean
	if not self.activityRequirements[activity] then
		return false
	else
		for memoryType, memoryStatus in pairs(self.activityRequirements[activity]) do
			if not self:checkMemory(memoryType, memoryStatus) then
				return false
			end
		end

		return true
	end
end

function Brain.eraseMemoriesForOtherActivitiesThan<T>(self: Brain<T>, activity: Activity): ()
	for activeActivity in pairs(self.activeActivities) do
		if activeActivity == activity then
			continue
		end

		local set = self.activityMemoriesToEraseWhenStopped[activeActivity]
		if set == nil then
			continue
		end

		for memoryType in pairs(set) do
			self:eraseMemory(memoryType)
		end
	end
end

function Brain.useDefaultActivity<T>(self: Brain<T>): ()
	self:setActiveActivity(self.defaultActivity)
end

function Brain.addActivity<T>(
	self: Brain<T>,
	activity: Activity,
	priority: number,
	behaviorControls: { BehaviorControl<T> }
): ()
	self:addActivityAndRemoveMemoriesWhenStopped(activity, self.createPriorityPairs(priority, behaviorControls), {}, {})
end

function Brain.addActivityWithConditions<T>(
	self: Brain<T>,
	activity: Activity,
	priority: number,
	behaviorControls: { BehaviorControl<T> },
	entryConditions: { [MemoryModuleType<any>]: MemoryStatus }
): ()
	self:addActivityAndRemoveMemoriesWhenStopped(activity, self.createPriorityPairs(priority, behaviorControls), entryConditions, {})
end

function Brain.addActivityAndRemoveMemoriesWhenStopped<T>(
	self: Brain<T>,
	activity: Activity,
	behaviorPairs: { { priority: number, behavior: BehaviorControl<T> } },
	memoryRequirementsSet: { [MemoryModuleType<any>]: MemoryStatus },
	memoriesToEraseSet: { [MemoryModuleType<any>]: true }
): ()
	self.activityRequirements[activity] = memoryRequirementsSet

	if not isEmptyTable(memoriesToEraseSet) then
		self.activityMemoriesToEraseWhenStopped[activity] = memoriesToEraseSet
	end

	for _, pair in ipairs(behaviorPairs) do
		local priority = pair.priority
		local behaviorControl = pair.behavior

		if self.availableBehaviorsByPriority[priority] == nil then
			self.availableBehaviorsByPriority[priority] = {}
		end

		local behaviorsByActivity = self.availableBehaviorsByPriority[priority]

		if behaviorsByActivity[activity] == nil then
			behaviorsByActivity[activity] = {}
		end

		local behaviorSet = behaviorsByActivity[activity]

		behaviorSet[behaviorControl] = true
	end
end

function Brain.createPriorityPairs<T>(
	startPriority: number,
	behaviors: { BehaviorControl<T> }
): { { priority: number, behavior: BehaviorControl<T> } }
	local priorityPairs = {}

	local currentPriority = startPriority
	for _, behaviorControl in ipairs(behaviors) do
		table.insert(priorityPairs, {
			priority = currentPriority,
			behavior = behaviorControl
		})
		currentPriority += 1
	end

	return priorityPairs
end

function Brain.isActivityActive<T>(self: Brain<T>, activity: Activity): boolean
	return self.activeActivities[activity] ~= nil
end

function Brain.getRunningBehaviors<T>(self: Brain<T>): { BehaviorControl<T> }
	local behaviorControlsArray = {}

	for _, activity in pairs(self.availableBehaviorsByPriority) do
		for _, behaviorControls in pairs(activity) do
			for behaviorControl in pairs(behaviorControls) do
				if behaviorControl:getStatus() ~= BehaviorControl.Status.RUNNING then
					continue
				end

				table.insert(behaviorControlsArray, behaviorControl)
			end
		end
	end

	return behaviorControlsArray
end

function Brain.update<T>(self: Brain<T>, deltaTime: number): ()
	self:forgetExpiredMemories(deltaTime)
	self:updateSensors(deltaTime)
	self:startEachNonRunningBehavior(deltaTime)
	self:updateEachRunningBehavior(deltaTime)
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

function Brain.startEachNonRunningBehavior<T>(self: Brain<T>, deltaTime: number): ()
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

				behaviorControl:tryStart(self.agent, currentTime, deltaTime)
			end
		end
	end
end

function Brain.updateEachRunningBehavior<T>(self: Brain<T>, deltaTime: number): ()
	local currentTime = tick()

	for _, behaviorControl in ipairs(self:getRunningBehaviors()) do
		behaviorControl:updateOrStop(self.agent, currentTime, deltaTime)
	end
end

return Brain