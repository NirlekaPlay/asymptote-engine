--!strict

--[=[
	@class WalkTarget
]=]
local WalkTarget = {}
WalkTarget.__index = WalkTarget

export type WalkTarget = typeof(setmetatable({} :: {
	target: Vector3,
	speedModifier: number,
	closeEnoughDist: number
}, WalkTarget))

function WalkTarget.new(
	target: Vector3,
	speedModifier: number,
	closeEnoughDist: number
): WalkTarget
	return setmetatable({
		target = target,
		speedModifier = speedModifier,
		closeEnoughDist = closeEnoughDist
	}, WalkTarget)
end

function WalkTarget.getTarget(self: WalkTarget): Vector3
	return self.target
end

function WalkTarget.getSpeedModifier(self: WalkTarget): number
	return self.speedModifier
end

function WalkTarget.getCloseEnoughDist(self: WalkTarget): number
	return self.closeEnoughDist
end

return WalkTarget