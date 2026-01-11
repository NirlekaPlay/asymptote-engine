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
	reached: boolean
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
		reached = false
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

function NodePath.getWaypointCount(self: NodePath): number
	return self.waypointCount
end

return NodePath