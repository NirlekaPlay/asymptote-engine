--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)

-- Some enums from `Door` that I'm too lazy to port.
local DoorTypes = {
	SINGLE = 0,
	DOUBLE = 1,
}

local DoorSides = {
	FRONT = 0,
	BACK = 1,
	MIDDLE = 2,
}

local DoorState = {
	OPEN = 0,
	OPENING = 1,
	CLOSED = 2,
	CLOSING = 3,
}

export type DoorType = number
type DoorSide = number
type DoorState = number

local SINGLE_SIDE_TO_KEY = {
	[DoorSides.FRONT] = "front",
	[DoorSides.BACK] = "back",
	[DoorSides.MIDDLE] = "middle",
}

local LOCALIZED_STRING_OPEN = "ui.prompt.open"
local LOCALIZED_STRING_CLOSE = "ui.prompt.close"

--[=[
	@class DoorPromptComponent

	A component responsible for managing the state and visibility of ProximityPrompts
	of a door, handling both single and double door configurations.
]=]
local DoorPromptComponent = {}
DoorPromptComponent.__index = DoorPromptComponent

type InteractionPrompt = WorldInteractionPrompt.WorldInteractionPrompt

export type SingleDoorPrompts = {
	front: {InteractionPrompt},
	back: {InteractionPrompt},
	middle: {InteractionPrompt}
}

export type DoubleDoorPrompts = {
	opening: {InteractionPrompt},
	closing: {InteractionPrompt},
	doorLeftFront: {InteractionPrompt},
	doorLeftBack: {InteractionPrompt},
	doorRightFront: {InteractionPrompt},
	doorRightBack: {InteractionPrompt},
	middle: {InteractionPrompt}
}

export type Prompts = SingleDoorPrompts | DoubleDoorPrompts

export type DoorPromptComponent = typeof(setmetatable({} :: {
	prompts: Prompts,
	doorType: DoorType,
}, DoorPromptComponent))

function DoorPromptComponent.new(
	prompts: Prompts,
	isDoubleDoor: boolean
): DoorPromptComponent
	
	local doorType = isDoubleDoor and DoorTypes.DOUBLE or DoorTypes.SINGLE

	local self: DoorPromptComponent = setmetatable({
		prompts = prompts,
		doorType = doorType,
	}, DoorPromptComponent)
	
	self:updateForState(DoorState.CLOSED, DoorSides.MIDDLE)

	return self
end

function DoorPromptComponent._setEnabled(self: DoorPromptComponent, sideKey: string, enabled: boolean): ()
	local prompts = (self.prompts :: any)[sideKey] :: { InteractionPrompt }
	if prompts then
		for _, prompt in prompts do
			if enabled then
				(prompt :: InteractionPrompt):enable()
			else
				(prompt :: InteractionPrompt):disable()
			end
		end
	end
end

function DoorPromptComponent._setActionText(self: DoorPromptComponent, sideKey: string, text: string): ()
	local prompts = (self.prompts :: any)[sideKey]
	if prompts then
		for _, prompt in prompts do
			(prompt :: InteractionPrompt):setTitleKey(text)
		end
	end
end

function DoorPromptComponent.setActionText(self: DoorPromptComponent, side: DoorSide, text: string): ()
	local key = SINGLE_SIDE_TO_KEY[side]
	if key and self.doorType == DoorTypes.SINGLE then
		self:_setActionText(key, text)
	end
end

function DoorPromptComponent.setEnabled(self: DoorPromptComponent, side: DoorSide, enabled: boolean): ()
	local key = SINGLE_SIDE_TO_KEY[side]
	if key and self.doorType == DoorTypes.SINGLE then
		self:_setEnabled(key, enabled)
	end
end

function DoorPromptComponent.updateForState(self: DoorPromptComponent, state: number, openingSide: number): ()
	local prompts = self.prompts

	-- 1. Handle TURNING States (OPENING/CLOSING): All prompts are disabled
	if state == DoorState.OPENING or state == DoorState.CLOSING then
		
		-- Disable all prompts regardless of door type
		for key, promptList in prompts :: any do
			self:_setEnabled(key, false)
		end
		return
	end

	-- 2. Handle Stationary States (CLOSED / OPEN)
	
	if self.doorType == DoorTypes.SINGLE then
		
		-- Default text for the main sides is Close
		self:_setActionText("front", LOCALIZED_STRING_CLOSE)
		self:_setActionText("back", LOCALIZED_STRING_CLOSE)
		self:_setActionText("middle", LOCALIZED_STRING_CLOSE)
		
		if state == DoorState.CLOSED then
			-- CLOSED: Front, Back = true (LOCALIZED_STRING_OPEN), Middle = false (LOCALIZED_STRING_CLOSE)
			self:_setEnabled("front", true)
			self:_setEnabled("back", true)
			self:_setEnabled("middle", false)
			self:_setActionText("front", LOCALIZED_STRING_OPEN)
			self:_setActionText("back", LOCALIZED_STRING_OPEN)
			
		elseif state == DoorState.OPEN then
			-- OPEN: Selective enabling based on openingSide, Middle is always true
			
			self:_setEnabled("middle", true)

			if openingSide == DoorSides.FRONT then
				-- Opened from FRONT: FRONT disabled, BACK enabled
				self:_setEnabled("front", false)
				self:_setEnabled("back", true)
			elseif openingSide == DoorSides.BACK then
				-- Opened from BACK: BACK disabled, FRONT enabled
				self:_setEnabled("front", true)
				self:_setEnabled("back", false)
			else
				-- If opened via MIDDLE or unknown, allow closing from both sides
				self:_setEnabled("front", true)
				self:_setEnabled("back", true)
			end
		end
		
	elseif self.doorType == DoorTypes.DOUBLE then
		
		-- Keys for double door prompts
		local allDoublePromptKeys = {
			"opening", "closing", "doorLeftFront", "doorLeftBack",
			"doorRightFront", "doorRightBack", "middle"
		}

		if state == DoorState.CLOSED then
			-- CLOSED: Opening, Closing = true, All others = false
			for _, key in allDoublePromptKeys do
				local enabled = (key == "opening" or key == "closing")
				self:_setEnabled(key, enabled)
			end
			
			self:_setActionText("opening", LOCALIZED_STRING_OPEN)
			self:_setActionText("closing", LOCALIZED_STRING_OPEN)
			
		elseif state == DoorState.OPEN then
			-- OPEN: Selective enabling based on openingSide, Middle is always true
			
			-- Disable Opening/Closing Prompts
			self:_setEnabled("opening", false)
			self:_setEnabled("closing", false)
			
			-- Set all active side/middle prompts to LOCALIZED_STRING_CLOSE
			self:_setActionText("doorLeftFront", LOCALIZED_STRING_CLOSE)
			self:_setActionText("doorLeftBack", LOCALIZED_STRING_CLOSE)
			self:_setActionText("doorRightFront", LOCALIZED_STRING_CLOSE)
			self:_setActionText("doorRightBack", LOCALIZED_STRING_CLOSE)
			self:_setActionText("middle", LOCALIZED_STRING_CLOSE)

			-- Middle prompt is always enabled when open
			self:_setEnabled("middle", true)

			if openingSide == DoorSides.FRONT then
				-- Opened from FRONT: Front side prompts disabled, Back side prompts enabled
				self:_setEnabled("doorLeftFront", false)
				self:_setEnabled("doorRightFront", false)
				self:_setEnabled("doorLeftBack", true)
				self:_setEnabled("doorRightBack", true)
			elseif openingSide == DoorSides.BACK then
				-- Opened from BACK: Back side prompts disabled, Front side prompts enabled
				self:_setEnabled("doorLeftFront", true)
				self:_setEnabled("doorRightFront", true)
				self:_setEnabled("doorLeftBack", false)
				self:_setEnabled("doorRightBack", false)
			else
				-- If opened via MIDDLE or unknown, allow closing from all side prompts
				self:_setEnabled("doorLeftFront", true)
				self:_setEnabled("doorRightFront", true)
				self:_setEnabled("doorLeftBack", true)
				self:_setEnabled("doorRightBack", true)
			end
		end
	end
end

return DoorPromptComponent