--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local BASE_WALK_SPEED = 16 -- Studs per sec
local DEBUG_WANTED_POS = false

--[=[
	@class MoveControl
]=]
local MoveControl = {}
MoveControl.__index = MoveControl

export type MoveControl = typeof(setmetatable({} :: {
	speedModifier: number,
	humanoid: Humanoid,
	_debugPoint: BasePart?
}, MoveControl))

function MoveControl.new(humanoid: Humanoid): MoveControl
	return setmetatable({
		speedModifier = 1,
		humanoid = humanoid,
		_debugPoint = nil :: BasePart?
	}, MoveControl)
end

function MoveControl.setWantedPosition(self: MoveControl, pos: Vector3, speedModifier: number): ()
	self.speedModifier = speedModifier
	self.humanoid.WalkSpeed = BASE_WALK_SPEED * speedModifier
	self.humanoid.WalkToPoint = pos
	if DEBUG_WANTED_POS then
		if self._debugPoint then
			self._debugPoint:Destroy()
		end

		self._debugPoint = Draw.point(pos)
	end
end

return MoveControl