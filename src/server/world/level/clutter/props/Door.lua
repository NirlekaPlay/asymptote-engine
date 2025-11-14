--!strict

--[=[
	@class Door
]=]
local Door = {
	States = {
		OPEN = 0,
		OPENING = 1,
		CLOSED = 2,
		CLOSING = 3
	},
	Sides = {
		FRONT = 0,
		BACK = 1,
		MIDDLE = 2
	}
}
Door.__index = Door

export type Door = typeof(setmetatable({} :: {
	state: DoorState,
	targetDegree: number,
	turningTimeAccum: number
}, Door))

export type DoorState = number

export type DoorSides = number

local TURNING_TIME = 1.5

local TARGET_DEGREES = {
	OPEN_FRONT = 90,
	OPEN_BACK = -90,
	CLOSED = 0
}

function Door.new(): Door
	return setmetatable({
		state = Door.States.CLOSED,
		targetDegree = 0,
		turningTimeAccum = 0
	}, Door)
end

function Door.isOpen(self: Door): boolean
	return self.state == Door.States.OPEN
end

function Door.isClosed(self: Door): boolean
	return self.state == Door.States.CLOSED
end

function Door.isTurning(self: Door): boolean
	return self.state == Door.States.CLOSING or
		self.state == Door.States.OPENING
end

function Door.onPromptTriggered(self: Door, promptSide: DoorSides): ()
	if self:isTurning() then
		return
	end

	if promptSide == Door.Sides.FRONT then
		self.targetDegree = self:isClosed() and TARGET_DEGREES.OPEN_BACK or TARGET_DEGREES.CLOSED
	elseif promptSide == Door.Sides.BACK then
		self.targetDegree = self:isOpen() and TARGET_DEGREES.OPEN_FRONT or TARGET_DEGREES.CLOSED
	else
		self.targetDegree = TARGET_DEGREES.CLOSED
	end

	if self.targetDegree == TARGET_DEGREES.OPEN_BACK or
		self.targetDegree == TARGET_DEGREES.OPEN_FRONT
	then
		self.state = Door.States.OPENING
	else
		self.state = Door.States.CLOSING
	end
end

function Door.update(self: Door, deltaTime: number): ()
	if self:isTurning() then
		self.turningTimeAccum += deltaTime
		if self.turningTimeAccum >= TURNING_TIME then
			self.turningTimeAccum = 0
			if self.state == Door.States.OPENING then
				self.state = Door.States.OPENED
				print("Open")
			else
				self.state = Door.States.CLOSED
				print("Closed")
			end
		end
	end
end

return Door