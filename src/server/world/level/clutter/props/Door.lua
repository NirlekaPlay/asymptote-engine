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
	openingSide: DoorSides,
	endCFrame: CFrame,
	prompts: DoorPrompts,
	promptsActivationDist: number,
}, Door))

export type DoorState = number

export type DoorSides = number

export type DoorPrompts = {
	front: ProximityPrompt,
	back: ProximityPrompt,
	middle: ProximityPrompt
}

local TURNING_TIME = 0.3

local TARGET_DEGREES = {
	OPEN_FRONT = 90,
	OPEN_BACK = -90,
	CLOSED = 0
}

function Door.new(hingePart: BasePart, prompts: DoorPrompts, promptsActivationDist: number): Door
	local self = setmetatable({
		state = Door.States.CLOSED,
		targetDegree = 0,
		turningTimeAccum = 0,
		hingePart = hingePart,
		startCFrame = hingePart.CFrame,
		endCFrame = hingePart.CFrame,
		openingSide = Door.Sides.MIDDLE,
		prompts = prompts,
		promptsActivationDist = promptsActivationDist
	}, Door)

	prompts.front.ActionText = "Open"
	prompts.back.ActionText = "Open"
	prompts.middle.ActionText = "Close"
	prompts.middle.Enabled = false

	return self
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

	local newTargetDegree: number

	if promptSide == Door.Sides.FRONT then
		newTargetDegree = self:isClosed() and TARGET_DEGREES.OPEN_FRONT or TARGET_DEGREES.CLOSED
	elseif promptSide == Door.Sides.BACK then
		newTargetDegree = self:isClosed() and TARGET_DEGREES.OPEN_BACK or TARGET_DEGREES.CLOSED
	else
		newTargetDegree = TARGET_DEGREES.CLOSED
	end

	if newTargetDegree == self.targetDegree then
		return
	end

	self.targetDegree = newTargetDegree
	self.turningTimeAccum = 0
	self.startCFrame = self.hingePart.CFrame

	local targetRadians = math.rad(self.targetDegree)
	
	local currentPosition = self.hingePart.CFrame.Position
	self.endCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, targetRadians, 0)
	
	if self.targetDegree == TARGET_DEGREES.OPEN_BACK or
		self.targetDegree == TARGET_DEGREES.OPEN_FRONT
	then
		self.state = Door.States.OPENING
		
		-- Track the side used to open, only if FRONT or BACK was used.
		if promptSide == Door.Sides.FRONT or promptSide == Door.Sides.BACK then
			self.openingSide = promptSide
		else
			self.openingSide = Door.Sides.MIDDLE
		end
		
		if promptSide == Door.Sides.FRONT then
			self.prompts.front.Enabled = false
		elseif promptSide == Door.Sides.BACK then
			self.prompts.back.Enabled = false
		end
	else -- Closing
		self.state = Door.States.CLOSING
		
		-- Temporarily disable all prompts during the closing animation to prevent interruption.
		self.prompts.front.Enabled = false
		self.prompts.back.Enabled = false
		self.prompts.middle.Enabled = false
	end
end

function Door.update(self: Door, deltaTime: number): ()
	if self:isTurning() then
		self.turningTimeAccum += deltaTime
		
		local alpha = math.clamp(self.turningTimeAccum / TURNING_TIME, 0, 1)

		self.hingePart.CFrame = self.startCFrame:Lerp(self.endCFrame, alpha)
		
		if self.turningTimeAccum >= TURNING_TIME then
			self.turningTimeAccum = 0
			
			self.hingePart.CFrame = self.endCFrame

			if self.state == Door.States.OPENING then
				self.state = Door.States.OPEN
				
				-- Door is now OPEN.
				
				if self.openingSide == Door.Sides.FRONT then
					self.prompts.back.Enabled = true  -- Opposite side is enabled for closing
					self.prompts.front.Enabled = false -- Opening side remains disabled
				elseif self.openingSide == Door.Sides.BACK then
					self.prompts.front.Enabled = true  -- Opposite side is enabled for closing
					self.prompts.back.Enabled = false -- Opening side remains disabled
				end

				self.prompts.middle.Enabled = true

				self.prompts.front.ActionText = "Close"
				self.prompts.back.ActionText = "Close"
				self.prompts.middle.ActionText = "Close"
				
			else
				self.state = Door.States.CLOSED
				
				-- Door is now CLOSED.
				self.prompts.front.Enabled = true
				self.prompts.back.Enabled = true
				self.prompts.middle.Enabled = false
				
				self.prompts.front.ActionText = "Open"
				self.prompts.back.ActionText = "Open"
				self.openingSide = Door.Sides.MIDDLE
			end
		end
	end
end

return Door