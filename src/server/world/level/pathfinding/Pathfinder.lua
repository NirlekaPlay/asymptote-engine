--!strict

local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local RblxAgentParameters = require(ServerScriptService.server.ai.navigation.RblxAgentParameters)
local NodeEvaluator = require(ServerScriptService.server.world.level.pathfinding.NodeEvaluator)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

--local DEBUG_WAYPOINT_REGION_CHECK = true
local DEBUG_PATHS = false
local DEBUG_START_FAIL_NODE_COLOR = Color3.fromRGB(255, 0, 0)
local DEBUG_END_FAIL_NODE_COLOR = Color3.fromRGB(255, 0, 0)
local DEBUG_NODES_SUCCESS_COLOR = Color3.fromRGB(0, 0, 255)
local DEBUG_LINE_COLOR = Color3.fromRGB(0, 0, 255)
local DEBUG_LINE_LIFETIME = 2
local DEBUG_NODES_SIZES = Vector3.new(1, 1, 1)
local DEBUG_ONLY_FAILED_NODES = true
local WARN_FAILED_PATH = false

--local DEFAULT_ENTITY_WIDTH = 4
--local DEFAULT_ENTITY_HEIGHT = 5

local debugNodesPerBlockPositions: { [Vector3]: { part: BasePart, boxAdorn: BoxHandleAdornment} } = {}

--[[local function getRegionFromWaypoint(position: Vector3, width: number, height: number): Region3
	local halfWidth = width / 2
	local min = Vector3.new(position.X - halfWidth, position.Y, position.Z - halfWidth)
	local max = Vector3.new(position.X + halfWidth, position.Y + height, position.Z + halfWidth)
	
	return Region3.new(min, max)
end]]

local function getBlockPosition(position: Vector3): Vector3
	return Vector3.new(
		math.floor(position.X),
		math.floor(position.Y),
		math.floor(position.Z)
	)
end

local function setDebugNode(pos: Vector3, color: Color3, success: boolean): ()
	local blockPos = getBlockPosition(pos)
	local existing = debugNodesPerBlockPositions[blockPos]
	if not existing and (DEBUG_ONLY_FAILED_NODES and not success) then
		local debugNode = Draw.box(CFrame.new(blockPos), DEBUG_NODES_SIZES, color)
		debugNode.Transparency = 1
		debugNodesPerBlockPositions[blockPos] = {
			part = debugNode,
			boxAdorn = debugNode:FindFirstChildOfClass("BoxHandleAdornment") :: BoxHandleAdornment
		}
	elseif existing then
		if existing.boxAdorn.Color3 ~= color then
			existing.boxAdorn.Color3 = color
		end
	end
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

	--local entityWidth = agentParams.AgentRadius and agentParams.AgentRadius * 2 or DEFAULT_ENTITY_WIDTH
	--local entityHeight = agentParams.AgentHeight or DEFAULT_ENTITY_HEIGHT

	-- TODO: Actually put the default entity widths / heights on the params itself
	local rblxPath = PathfindingService:CreatePath(agentParams :: any)
	rblxPath:ComputeAsync(startPos, endPos)

	if rblxPath.Status == Enum.PathStatus.Success then
		if DEBUG_PATHS then
			setDebugNode(startPos, DEBUG_NODES_SUCCESS_COLOR, true)
			setDebugNode(endPos, DEBUG_NODES_SUCCESS_COLOR, true)
		end
		local waypoints = rblxPath:GetWaypoints()
		--[[for _, waypoint in waypoints do
			if waypoint.Label == "Door" then

			end
		end]]

		return NodePath.new(waypoints, endPos)
	else
		if WARN_FAILED_PATH then
			warn(`Failed to find path from start pos {startPos} to {endPos}; Path status: '{rblxPath.Status.Name}'`)
		end
		if DEBUG_PATHS then
			setDebugNode(startPos, DEBUG_START_FAIL_NODE_COLOR, false)
			setDebugNode(endPos, DEBUG_END_FAIL_NODE_COLOR, false)
			Debris:AddItem(Draw.line(startPos, endPos, DEBUG_LINE_COLOR), DEBUG_LINE_LIFETIME)
		end
		return nil
	end
end

return Pathfinder