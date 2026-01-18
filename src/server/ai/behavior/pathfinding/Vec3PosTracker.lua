--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PositionTracker = require(ServerScriptService.server.ai.behavior.pathfinding.PositionTracker)

--[=[
	@class Vec3PosTracker
]=]
local Vec3PosTracker = {}
Vec3PosTracker.__index = Vec3PosTracker

export type Vec3PosTracker = PositionTracker.PositionTracker & typeof(setmetatable({} :: {
	pos: Vector3,
	cachedBlockPos: Vector3?
}, Vec3PosTracker))

function Vec3PosTracker.new(pos: Vector3): Vec3PosTracker
	return setmetatable({
		pos = pos,
		cachedBlockPos = nil
	}, Vec3PosTracker) :: Vec3PosTracker
end

function Vec3PosTracker.getCurrentPosition(self: Vec3PosTracker): Vector3
	return self.pos
end

function Vec3PosTracker.getBlockPosition(self: Vec3PosTracker): Vector3
	if self.cachedBlockPos then
		return self.cachedBlockPos
	end

	self.cachedBlockPos = Vector3.new(
		math.floor(self.pos.X),
		math.floor(self.pos.Y),
		math.floor(self.pos.Z)
	)

	return self.cachedBlockPos
end

return Vec3PosTracker