--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DoorHingeComponent = require(ServerScriptService.server.world.level.clutter.props.DoorHingeComponent)
local DoorPromptComponent = require(ServerScriptService.server.world.level.clutter.props.DoorPromptComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

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
	promptComponent: DoorPromptComponent.DoorPromptComponent,
	hingeComponent: DoorHingeComponent.DoorHingeComponent,
	openingSide: DoorSides,
	doorParts: {BasePart},
	lockFront: boolean,
	lockBack: boolean,
	settingLockFront: boolean,
	settingLockBack: boolean,
	autoLock: boolean,
	unlockVariable: string?
}, Door))

export type DoorState = number

export type DoorSides = number

export type DoorPrompts = {
	front: {ProximityPrompt},
	back: {ProximityPrompt},
	middle: {ProximityPrompt}
}

local TURNING_TIME = 0.3

local TARGET_DEGREES = {
	OPEN_FRONT = 90,
	OPEN_BACK = -90,
	CLOSED = 0
}

function Door.new(
	hingePart: BasePart,
	prompts: DoorPrompts,
	promptComponent: DoorPromptComponent.DoorPromptComponent,
	hingeComponent: DoorHingeComponent.DoorHingeComponent,
	doorParts: {BasePart}?,
	lockFront: boolean?,
	lockBack: boolean?,
	autoLock: boolean?,
	unlockVariable: string?
): Door
	local self = setmetatable({
		state = Door.States.CLOSED,
		targetDegree = 0,
		turningTimeAccum = 0,
		promptComponent = promptComponent,
		hingeComponent = hingeComponent,
		openingSide = Door.Sides.MIDDLE,
		doorParts = doorParts or {},
		lockFront = lockFront or false,
		lockBack = lockBack or false,
		settingLockFront = lockFront or false,
		settingLockBack = lockBack or false,
		autoLock = autoLock or false,
		unlockVariable = unlockVariable
	}, Door)

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

function Door.unlockBothSides(self: Door): ()
	self.lockFront = false
	self.lockBack = false
end

function Door.onPromptTriggered(self: Door, promptSide: DoorSides): ()
	if self:isTurning() then
		return
	end

	local newTargetDegree: number

	-- Determine the intended action: OPEN or CLOSE
	if promptSide == Door.Sides.FRONT then
		newTargetDegree = self:isClosed() and TARGET_DEGREES.OPEN_FRONT or TARGET_DEGREES.CLOSED
	elseif promptSide == Door.Sides.BACK then
		newTargetDegree = self:isClosed() and TARGET_DEGREES.OPEN_BACK or TARGET_DEGREES.CLOSED
	elseif promptSide == Door.Sides.MIDDLE then
		newTargetDegree = TARGET_DEGREES.CLOSED
	else
		newTargetDegree = TARGET_DEGREES.CLOSED
	end

	-- The middle prompt should only be used for closing, so if the target is OPEN, return immediately.
	if promptSide == Door.Sides.MIDDLE and newTargetDegree ~= TARGET_DEGREES.CLOSED then
		return
	end
	
	-- Check locks ONLY if the door is currently CLOSED and the target is OPENING (i.e., this is an OPEN attempt)
	if self:isClosed() and newTargetDegree ~= TARGET_DEGREES.CLOSED then
		if (promptSide == Door.Sides.FRONT and self.lockFront) or
			(promptSide == Door.Sides.BACK and self.lockBack) then
			return
		end
	end

	-- What the fuck?
	self.lockFront = false
	self.lockBack = false

	if newTargetDegree == self.targetDegree then
		return
	end

	self.targetDegree = newTargetDegree
	self.turningTimeAccum = 0
	(self.hingeComponent :: DoorHingeComponent.DoorHingeComponent):turnToDegrees(self.targetDegree)
	
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
		
		-- Set the appropriate lock settings for autolock upon closing
		if promptSide == Door.Sides.FRONT then
			-- Opened from FRONT, so upon closing, the BACK side should be locked (if autolock is on)
			self.lockFront = false
			self.lockBack = true
		elseif promptSide == Door.Sides.BACK then
			-- Opened from BACK, so upon closing, the FRONT side should be locked (if autolock is on)
			self.lockFront = true
			self.lockBack = false
		end

		self:setDoorPartsCollision(false)
	else -- Closing
		self.state = Door.States.CLOSING
		self:setDoorPartsCollision(false)
	end

	-- Remote unlock
	if self.unlockVariable and GlobalStatesHolder.hasState(self.unlockVariable) then
		GlobalStatesHolder.setState(self.unlockVariable, self.state == Door.States.OPENING and true or false)
	end

	-- Prompts
	(self.promptComponent :: DoorPromptComponent.DoorPromptComponent):updateForState(self.state, self.openingSide)
end

function Door.update(self: Door, deltaTime: number): ()
	if self:isTurning() then
		self.turningTimeAccum += deltaTime;
		
		(self.hingeComponent :: DoorHingeComponent.DoorHingeComponent):update(TURNING_TIME, deltaTime)
		
		if self.turningTimeAccum >= TURNING_TIME then
			self.turningTimeAccum = 0

			if self.state == Door.States.OPENING then
				self.state = Door.States.OPEN;
				
				-- Door is now OPEN.
				
				-- Prompts
				(self.promptComponent :: DoorPromptComponent.DoorPromptComponent):updateForState(self.state, self.openingSide)
				self:setDoorPartsCollision(true)
			else
				self.state = Door.States.CLOSED
				
				-- Door is now CLOSED.
				
				-- AutoLock Logic.
				if self.autoLock then
					-- self.settingLockFront/Back was set during the opening phase to reflect the
					-- desired locked state upon closing.
					self.lockFront = self.settingLockFront
					self.lockBack = self.settingLockBack
				end
				
				-- Prompts
				(self.promptComponent :: DoorPromptComponent.DoorPromptComponent):updateForState(self.state, self.openingSide)
				self.openingSide = Door.Sides.MIDDLE
				self:setDoorPartsCollision(true)
			end
		end
	end
end

function Door.setDoorPartsCollision(self: Door, canCollide: boolean): ()
	if next(self.doorParts) == nil then
		return
	end

	for _, part in self.doorParts do
		part.CanCollide = canCollide
	end
end

return Door