--!strict

local PathfindingService = game:GetService("PathfindingService")
local ServerScriptService = game:GetService("ServerScriptService")
local RblxAgentParameters = require(ServerScriptService.server.ai.navigation.RblxAgentParameters)
local NodeEvaluator = require(ServerScriptService.server.world.level.pathfinding.NodeEvaluator)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

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

function Pathfinder.getNodeEvaluator(self: Pathfinder): NodeEvaluator.NodeEvaluator
	return self.nodeEvaluator
end

function Pathfinder.findPathAsync(
	self: Pathfinder,
	startPos: Vector3,
	endPos: Vector3,
	agentParams: RblxAgentParameters.AgentParameters
): NodePath.NodePath?

	local rblxPath = PathfindingService:CreatePath(agentParams :: any)
	rblxPath:ComputeAsync(startPos, endPos)

	if rblxPath.Status == Enum.PathStatus.Success then
		local refined = self:refinePathForDoors(rblxPath:GetWaypoints(), agentParams)

		return NodePath.new(refined, endPos)
	else
		return nil
	end
end

--

function Pathfinder.refinePathForDoors(
	self: Pathfinder,
	waypoints: {PathWaypoint},
	agentParams: RblxAgentParameters.AgentParameters
): {PathWaypoint}

	local newWaypoints: {PathWaypoint} = {}
	local numWaypoints = #waypoints
	
	local i = 1
	while i <= numWaypoints do
		local waypoint = waypoints[i]
		local overlaps = self.nodeEvaluator:getDoorBoundPartsAt(waypoint.Position)
		local doorPart = overlaps[1] :: BasePart?

		if doorPart and self.nodeEvaluator:isWaypointDoor(waypoint) then
			local lastDoorIdx = i
			
			while lastDoorIdx + 1 <= numWaypoints do
				local nextWp = waypoints[lastDoorIdx + 1]
				local nextOverlaps = self.nodeEvaluator:getDoorBoundPartsAt(nextWp.Position)
				if nextOverlaps[1] == doorPart then
					lastDoorIdx += 1
				else
					break
				end
			end

			if next(newWaypoints) ~= nil then
				local newWaypointsCount = #newWaypoints
				local entryWp = newWaypoints[newWaypointsCount]
				local toDoor = (doorPart.Position - entryWp.Position).Unit
				local entryPos = doorPart.Position - (toDoor * (agentParams.AgentRadius or 2))
				
				newWaypoints[newWaypointsCount] = {
					Position = Vector3.new(entryPos.X, entryWp.Position.Y, entryPos.Z),
					Action = entryWp.Action,
					Label = entryWp.Label
				}
			end

			table.insert(newWaypoints, {
				Position = Vector3.new(doorPart.Position.X, waypoint.Position.Y, doorPart.Position.Z),
				Action = waypoint.Action,
				Label = waypoint.Label
			})

			if lastDoorIdx < numWaypoints then
				local exitWp = waypoints[lastDoorIdx + 1]
				local fromDoor = (exitWp.Position - doorPart.Position).Unit
				local exitPos = doorPart.Position + (fromDoor * (agentParams.AgentRadius or 2))
				
				table.insert(newWaypoints, {
					Position = Vector3.new(exitPos.X, exitWp.Position.Y, exitPos.Z),
					Action = exitWp.Action,
					Label = exitWp.Label
				})

				i = lastDoorIdx + 2
			else
				i = lastDoorIdx + 1
			end
		else
			table.insert(newWaypoints, waypoint)
			i += 1
		end
	end

	return newWaypoints
end

return Pathfinder