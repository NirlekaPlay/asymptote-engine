--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PositionTracker = require(ServerScriptService.server.ai.behavior.pathfinding.PositionTracker)

--[=[
	@class Vec3PosTracker
]=]
local Vec3PosTracker = {}
Vec3PosTracker.__index = Vec3PosTracker

export type Vec3PosTracker = PositionTracker.PositionTracker & typeof(setmetatable({} :: {
	pos: Vector3
}, Vec3PosTracker))

function Vec3PosTracker.new(pos: Vector3): Vec3PosTracker
	return setmetatable({
		pos = pos
	}, Vec3PosTracker) :: Vec3PosTracker
end

function Vec3PosTracker.getCurrentPosition(self: Vec3PosTracker): Vector3
	return self.pos
end

return Vec3PosTracker