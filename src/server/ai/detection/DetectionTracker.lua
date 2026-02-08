--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectableEntity = require(ServerScriptService.server.ai.detection.entity.DetectableEntity)

--[=[
	@class DetectionTracker
]=]
local DetectionTracker = {}
DetectionTracker.__index = DetectionTracker

export type DetectionTracker = typeof(setmetatable({} :: {
	source: DetectableEntity.DetectableEntity,
	value: number,
	lastSeenAt: number
}, DetectionTracker))

function DetectionTracker.new(source: DetectableEntity.DetectableEntity): DetectionTracker
	return setmetatable({
		source = source,
		value = 0.0,
		lastSeenAt = os.clock()
	}, DetectionTracker)
end

function DetectionTracker.increase(self: any, amount: number): ()
	self.value = math.clamp(self.value + amount, 0, 1)
	self.lastSeenAt = os.clock()
end

function DetectionTracker.decay(self: any, rate: number, dt: number): ()
	self.value = math.max(0, self.value - (rate * dt))
end

return DetectionTracker