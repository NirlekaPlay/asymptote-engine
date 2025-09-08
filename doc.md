`SensorFactory` is just a registry class. Used by the Brain during initialization.<br/>
It just has the method `create()` which returns a `SensorWrapper` instance, wrapping the
constructor function of the `Sensor` instance itself.

```lua
function SensorFactory.new(sensorConstructor: () -> Sensor.Sensor<any>): SensorFactory<any>
	return setmetatable({
		create = function()
			return SensorWrapper.new(sensorConstructor())
		end
	}, SensorFactory)
end
```

in `SensorFactories.lua`:

```lua
return {
	VISIBLE_PLAYERS_SENSOR = SensorFactory.new(VisiblePlayersSensor.new),
	-- ...
}
```

`SensorFactory` gets the constructor of a Sensor class, in this example is the VisiblePlayerSensor,


For example, in GuardAi.lua:

```lua
function GuardAi.makeBrain(guard: Agent)
	local brain = Brain.new(guard, MEMORY_TYPES, SENSOR_TYPES)
		-- ...
end
```

`SENSOR_TYPES` is an array of `SensorFactory`. In `Brain.new()`:

```lua
function Brain.new<T>(agent: T, memories: { MemoryModuleType<any> }, sensors: { SensorFactory<T> } ): Brain<T>
	local self = {} :: self<T>

	-- ...
	self.sensors = {}
	-- ...

	for _, SensorFactory in ipairs(sensors) do
		self.sensors[SensorFactory] = SensorFactory.create()
	end

	return setmetatable(self, Brain)
end
```

`SensorFactory.create()` Returns an instance of `SensorWrapper` which the brain actually interacts with in the
update function:

```lua
function Brain.updateSensors<T>(self: Brain<T>, deltaTime: number): ()
	for _, sensor in pairs(self.sensors) do
		sensor:update(self.agent, deltaTime)
	end
end
```

`SensorWrapper` right now just wraps around a `Sensor` class so it doesnt have to manually accumulate time.
For example one sensor updates 20 times per second, while the other updates only once per second.