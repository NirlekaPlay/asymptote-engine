--!strict

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
	turningTimeAccum: number
}, DoorHingeComponent))

export type Hinge = {
	part: BasePart,
	startCFrame: CFrame,
	endCFrame: CFrame
}

function DoorHingeComponent.new(hinges: { Hinge }, isDouble: boolean): DoorHingeComponent
	return setmetatable({
		hinges = hinges,
		double = isDouble,
		turningTimeAccum = 0
	}, DoorHingeComponent)
end

function DoorHingeComponent.single(hingePart: BasePart): DoorHingeComponent
	return DoorHingeComponent.new({{
		part = hingePart,
		startCFrame = hingePart.CFrame,
		endCFrame = hingePart.CFrame
	}}, false)
end

function DoorHingeComponent.double(hingePart1: BasePart, hingePart2: BasePart): DoorHingeComponent
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
		}, true)
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
end

function DoorHingeComponent.setHingeTargetCFrame(hinge: Hinge, degrees: number): ()
	local targetRadians = math.rad(degrees)
	local cframe = hinge.part.CFrame
	local currentPosition = cframe.Position
	hinge.startCFrame = cframe
	hinge.endCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, targetRadians, 0)
end

function DoorHingeComponent.update(self: DoorHingeComponent, turningTime: number, deltaTime: number): ()
	self.turningTimeAccum += deltaTime
	for i, hinge in self.hinges do
		local alpha = math.clamp(self.turningTimeAccum / turningTime, 0, 1)
		hinge.part.CFrame = hinge.startCFrame:Lerp(hinge.endCFrame, alpha)
	end

	if self.turningTimeAccum >= turningTime then
		self.turningTimeAccum = 0
		for i, hinge in self.hinges do
			hinge.part.CFrame = hinge.endCFrame
		end
	end
end

return DoorHingeComponent