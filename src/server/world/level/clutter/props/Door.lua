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
	turningTimeAccum: number,
	hingePart: BasePart,
	startCFrame: CFrame,
	endCFrame: CFrame,
}, Door))

export type DoorState = number

export type DoorSides = number

local TURNING_TIME = 0.3

local TARGET_DEGREES = {
	OPEN_FRONT = 90,
	OPEN_BACK = -90,
	CLOSED = 0
}

function Door.new(hingePart: BasePart): Door
	return setmetatable({
		state = Door.States.CLOSED,
		targetDegree = 0,
		turningTimeAccum = 0,
		hingePart = hingePart,
		-- Initialize CFrames to prevent errors
		startCFrame = hingePart.CFrame,
		endCFrame = hingePart.CFrame
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

-- Revised function to capture the starting CFrame and set the target CFrame
function Door.onPromptTriggered(self: Door, promptSide: DoorSides): ()
	if self:isTurning() then
		return
	end

	local newTargetDegree: number

	-- Determine the target rotation degree
	if promptSide == Door.Sides.FRONT then
		newTargetDegree = self:isClosed() and TARGET_DEGREES.OPEN_BACK or TARGET_DEGREES.CLOSED
	elseif promptSide == Door.Sides.BACK then
		newTargetDegree = self:isOpen() and TARGET_DEGREES.OPEN_FRONT or TARGET_DEGREES.CLOSED
	else
		newTargetDegree = TARGET_DEGREES.CLOSED
	end

	-- If the door is already at the target degree, do nothing (e.g., trying to close a closed door)
	if newTargetDegree == self.targetDegree then
		-- Optional: Add a check if the current hingePart.CFrame matches the target degree before returning.
		return
	end

	-- Set up for the transition
	self.targetDegree = newTargetDegree
	self.turningTimeAccum = 0 -- Reset accumulator for the new animation
	self.startCFrame = self.hingePart.CFrame -- **Crucial:** Capture the starting CFrame
	
	-- Calculate the final target CFrame
	local targetRadians = math.rad(self.targetDegree)
	
	-- The end CFrame preserves the Part's original Position but applies the new rotation
	local currentPosition = self.hingePart.CFrame.Position
	self.endCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, targetRadians, 0)
	
	-- Set the new state
	if self.targetDegree == TARGET_DEGREES.OPEN_BACK or
		self.targetDegree == TARGET_DEGREES.OPEN_FRONT
	then
		self.state = Door.States.OPENING
	else
		self.state = Door.States.CLOSING
	end
end

-- Revised function for CFrame interpolation
function Door.update(self: Door, deltaTime: number): ()
	if self:isTurning() then
		self.turningTimeAccum += deltaTime
		
		-- Calculate the interpolation factor (alpha), clamped between 0 and 1
		local alpha = math.clamp(self.turningTimeAccum / TURNING_TIME, 0, 1)

		-- Interpolate the CFrame using the stored start and end CFrames
		self.hingePart.CFrame = self.startCFrame:Lerp(self.endCFrame, alpha)
		
		-- Check for completion
		if self.turningTimeAccum >= TURNING_TIME then
			self.turningTimeAccum = 0
			
			-- **Crucial:** Snap the CFrame to the exact end position to eliminate floating point errors
			self.hingePart.CFrame = self.endCFrame
			
			-- Transition to the final state
			if self.state == Door.States.OPENING then
				self.state = Door.States.OPEN
				print("Open")
			else
				self.state = Door.States.CLOSED
				print("Closed")
			end
		end
	end
end

return Door