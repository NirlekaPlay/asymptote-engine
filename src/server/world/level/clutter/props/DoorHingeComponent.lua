--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local DEFAULT_TURNING_TIME = 0.3

--[=[
	@class DoorHingeComponent

	A component responsible for managing the turning of hinge parts,
	handling both single and double door configurations.
]=]
local DoorHingeComponent = {}
DoorHingeComponent.__index = DoorHingeComponent

export type DoorHingeComponent = typeof(setmetatable({} :: {
	hinges: { Hinge },
	double: boolean,
	turningTimeAccum: number,
	turningTime: number
}, DoorHingeComponent))

export type Hinge = {
	part: BasePart,
	startCFrame: CFrame,
	endCFrame: CFrame
}

function DoorHingeComponent.new(hinges: { Hinge }, isDouble: boolean, turningTime: number): DoorHingeComponent
	return setmetatable({
		hinges = hinges,
		double = isDouble,
		turningTimeAccum = 0,
		turningTime = turningTime
	}, DoorHingeComponent)
end

function DoorHingeComponent.single(hingePart: BasePart, turningTime: number?): DoorHingeComponent
	return DoorHingeComponent.new({{
		part = hingePart,
		startCFrame = hingePart.CFrame,
		endCFrame = hingePart.CFrame,
	}}, false, turningTime or DEFAULT_TURNING_TIME)
end

function DoorHingeComponent.double(hingePart1: BasePart, hingePart2: BasePart, turningTime: number?): DoorHingeComponent
	return DoorHingeComponent.new(
		{
			{
				part = hingePart1,
				startCFrame = hingePart1.CFrame,
				endCFrame = hingePart1.CFrame
			},
			{
				part = hingePart2,
				startCFrame = hingePart2.CFrame,
				endCFrame = hingePart2.CFrame
			}
		}, true, turningTime or DEFAULT_TURNING_TIME)
end

--

function DoorHingeComponent.isDouble(self: DoorHingeComponent): boolean
	return self.double
end

function DoorHingeComponent.turnToDegrees(self: DoorHingeComponent, degrees: number): ()
	self.turningTimeAccum = 0
	DoorHingeComponent.setHingeTargetCFrame(self.hinges[1], degrees)
	if self:isDouble() then
		DoorHingeComponent.setHingeTargetCFrame(self.hinges[2], -degrees)
	end

	for _, hinge in self.hinges do
		TypedRemotes.ClientBoundTween:FireAllClients({
			instance = hinge.part,
			tweenInfo = {
				time = self.turningTime,
				easingStyle = Enum.EasingStyle.Sine,
				easingDirection = degrees ~= 0 and Enum.EasingDirection.InOut or Enum.EasingDirection.In,
				repeatCount = 0,
				reverses = false,
				delayTime = 0
			},
			properties = {
				CFrame = hinge.endCFrame
			}
		})
	end
end

function DoorHingeComponent.setHingeTargetCFrame(hinge: Hinge, degrees: number): ()
	local targetRadians = math.rad(degrees)
	local cframe = hinge.part.CFrame
	local currentPosition = cframe.Position
	hinge.startCFrame = cframe
	hinge.endCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, targetRadians, 0)
end

function DoorHingeComponent.applyHingeDegrees(hinge: Hinge, degrees: number): ()
	local targetRadians = math.rad(degrees)
	local cframe = hinge.startCFrame
	local currentPosition = cframe.Position
	
	local finalCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, targetRadians, 0)

	hinge.part.CFrame = finalCFrame
	
	-- NOTE: Also update the startCFrame and endCFrame to reflect the new state, 
	-- ensuring future `update` calls start from the correct position if necessary.
	hinge.startCFrame = finalCFrame
	hinge.endCFrame = finalCFrame
end

function DoorHingeComponent.setDegrees(self: DoorHingeComponent, degrees: number): ()
	DoorHingeComponent.applyHingeDegrees(self.hinges[1], degrees)

	if self:isDouble() then
		DoorHingeComponent.applyHingeDegrees(self.hinges[2], -degrees)
	end

	self.turningTimeAccum = 0
end

function DoorHingeComponent.update(self: DoorHingeComponent, deltaTime: number): ()
	self.turningTimeAccum += deltaTime
	if self.turningTimeAccum >= self.turningTime then
		self.turningTimeAccum = 0
		for i, hinge in self.hinges do
			hinge.part.CFrame = hinge.endCFrame
		end
	end
end

return DoorHingeComponent