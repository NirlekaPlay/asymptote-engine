--!strict

--[=[
	@class NodePath
]=]
local NodePath = {}
NodePath.__index = NodePath

export type NodePath = typeof(setmetatable({} :: {
	waypoints: { PathWaypoint },
	waypointCount: number,
	nextWaypointIndex: number,
	target: Vector3,
	distToTarget: number,
	reached: boolean,
	totalLengthCache: number?
}, NodePath))

function NodePath.new(
	waypoints: { PathWaypoint },
	target: Vector3,
	distToTarget: number
): NodePath
	return setmetatable({
		waypoints = waypoints,
		waypointCount = #waypoints,
		nextWaypointIndex = 0,
		target = target,
		distToTarget = distToTarget,
		reached = false,
		totalLengthCache = nil :: number?
	}, NodePath)
end

function NodePath.advance(self: NodePath): ()
	self.nextWaypointIndex += 1
end

function NodePath.hasNotStarted(self: NodePath): boolean
	return self.nextWaypointIndex <= 0
end

function NodePath.isDone(self: NodePath): boolean
	return self.nextWaypointIndex >= self.waypointCount
end

function NodePath.getNextNode(self: NodePath): PathWaypoint
	return self.waypoints[self.nextWaypointIndex]
end

function NodePath.getWaypoints(self: NodePath): {PathWaypoint}
	return self.waypoints
end

function NodePath.getWaypointCount(self: NodePath): number
	return self.waypointCount
end

function NodePath.getTotalLength(self: NodePath): number
	if self.totalLengthCache then
		return self.totalLengthCache
	end

	local pathCost = 0
	for i = 2, self:getWaypointCount() do
		pathCost = pathCost + (self.waypoints[i].Position - self.waypoints[i-1].Position).Magnitude
	end

	self.totalLengthCache = pathCost
	return pathCost
end

return NodePath