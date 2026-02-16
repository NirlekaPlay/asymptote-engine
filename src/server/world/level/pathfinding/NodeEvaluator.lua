--!strict

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionTags = require(ServerScriptService.server.collection.CollectionTags)
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)

--[=[
	@class NodeEvaluator
]=]
local NodeEvaluator = {}
NodeEvaluator.__index = NodeEvaluator

export type NodeEvaluator = typeof(setmetatable({} :: {
	
}, NodeEvaluator))

function NodeEvaluator.new(
): NodeEvaluator
	return setmetatable({
	}, NodeEvaluator)
end

function NodeEvaluator.isWaypointDoor(self: NodeEvaluator, waypoint: PathWaypoint): boolean
	return waypoint.Label == "Door" or waypoint.Label == "DoorPerpendicularPart"
end

function NodeEvaluator.getDoorBoundPartsAt(self: NodeEvaluator, atPos: Vector3): {BasePart}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged(CollectionTags.DOOR_PATH_BOUNDS)
	return workspace:GetPartBoundsInRadius(atPos, 5, overlapParams)
end

function NodeEvaluator.canOpenDoors(self: NodeEvaluator): boolean
	return true
end

function NodeEvaluator.canOpenDoor(self: NodeEvaluator, door: Door.Door): boolean
	return true
end


return NodeEvaluator