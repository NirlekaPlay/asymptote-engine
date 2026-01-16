--!strict

local PathfindingService = game:GetService("PathfindingService")
local ServerScriptService = game:GetService("ServerScriptService")
local RblxAgentParameters = require(ServerScriptService.server.ai.navigation.RblxAgentParameters)
local NodeEvaluator = require(ServerScriptService.server.world.level.pathfinding.NodeEvaluator)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

local DEBUG_WAYPOINT_REGION_CHECK = true
local WARN_FAILED_PATH = false

local DEFAULT_ENTITY_WIDTH = 4
local DEFAULT_ENTITY_HEIGHT = 5

local function getRegionFromWaypoint(position: Vector3, width: number, height: number): Region3
	local halfWidth = width / 2
	local min = Vector3.new(position.X - halfWidth, position.Y, position.Z - halfWidth)
	local max = Vector3.new(position.X + halfWidth, position.Y + height, position.Z + halfWidth)
	
	return Region3.new(min, max)
end

--[=[
	@class Pathfinder
]=]
local Pathfinder = {}
Pathfinder.__index = Pathfinder

export type Pathfinder = typeof(setmetatable({} :: {
	nodeEvaluator: NodeEvaluator.NodeEvaluator
}, Pathfinder))

function Pathfinder.new(): Pathfinder
	return setmetatable({
		nodeEvaluator = NodeEvaluator.new()
	}, Pathfinder)
end

function Pathfinder.findPathAsync(
	self: Pathfinder,
	startPos: Vector3,
	endPos: Vector3,
	agentParams: RblxAgentParameters.AgentParameters
): NodePath.NodePath?

	local entityWidth = agentParams.AgentRadius and agentParams.AgentRadius * 2 or DEFAULT_ENTITY_WIDTH
	local entityHeight = agentParams.AgentHeight or DEFAULT_ENTITY_HEIGHT

	-- TODO: Actually put the default entity widths / heights on the params itself
	local rblxPath = PathfindingService:CreatePath(agentParams :: any)
	rblxPath:ComputeAsync(startPos, endPos)

	if rblxPath.Status == Enum.PathStatus.Success then
		local waypoints = rblxPath:GetWaypoints()
		--[[for _, waypoint in waypoints do
			if waypoint.Label == "Door" then

			end
		end]]

		return NodePath.new(waypoints, endPos, 1)
	else
		if WARN_FAILED_PATH then
			warn(`Failed to find path from start pos {startPos} to {endPos}; Path status: '{rblxPath.Status.Name}'`)
		end
		return nil
	end
end

return Pathfinder