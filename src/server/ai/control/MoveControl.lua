--!strict

local BASE_WALK_SPEED = 16 -- Studs per sec

--[=[
	@class MoveControl
]=]
local MoveControl = {}
MoveControl.__index = MoveControl

export type MoveControl = typeof(setmetatable({} :: {
	speedModifier: number,
	humanoid: Humanoid
}, MoveControl))

function MoveControl.new(humanoid: Humanoid): MoveControl
	return setmetatable({
		speedModifier = 1,
		humanoid = humanoid
	}, MoveControl)
end

function MoveControl.setWantedPosition(self: MoveControl, pos: Vector3, speedModifier: number): ()
	self.humanoid.WalkToPoint = pos
	self.speedModifier = speedModifier
	self.humanoid.WalkSpeed = BASE_WALK_SPEED * speedModifier
end

return MoveControl