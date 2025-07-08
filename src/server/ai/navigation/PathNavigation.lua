--!nonstrict

local PathfindingService = game:GetService("PathfindingService")

local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type AgentParameters = {
	AgentRadius: number, -- these 2 values are useful so the agent wont get stuck in tight corners
	AgentHeight: number,
	AgentCanJump: boolean, -- due to the nature of our games, these 2 values are not necessary, leave them as false
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	Costs: {any}
}

export type PathNavigation = typeof(setmetatable({} :: {
	character: Model,
	path: Path?,
	pathAgentParams: AgentParameters?,
	waypoints: { PathWaypoint },
	currentWaypointIndex: number,
	humanoidMoveToFinishedConnection: RBXScriptConnection?,
	finished: boolean
}, PathNavigation))

function PathNavigation.new(character: Model, agentParams: AgentParameters?): PathNavigation
	return setmetatable({
		character = character,
		path = nil :: Path?,
		pathAgentParams = agentParams,
		waypoints = {},
		currentWaypointIndex = 1,
		humanoidMoveToFinishedConnection = nil :: RBXScriptConnection?,
		finished = false
	}, PathNavigation)
end

function PathNavigation.createPath(self: PathNavigation, toPos: Vector3): Path
	-- pathfinding service in roblox is very weird.
	-- a "path" is just a configured class that we use to compute and also
	-- get the waypoints.

	local path = PathfindingService:CreatePath(self.pathAgentParams)
	path:ComputeAsync(self.character.PrimaryPart.Position, toPos)
	local waypoints = path:GetWaypoints()

	self.path = path
	self.waypoints = waypoints
	self.currentWaypointIndex = 2
	self.finished = false

	return path
end

function PathNavigation.disconnectMoveToConnection(self: PathNavigation): ()
	local connection = self.humanoidMoveToFinishedConnection
	if connection then
		connection:Disconnect()
		self.humanoidMoveToFinishedConnection = nil
	end
end

function PathNavigation.moveTo(self: PathNavigation, toPos: Vector3): ()
	-- reset for good measure (remove if causing performance problems)
	-- for now, we dont implement a blocked or stuck handling
	self:createPath(toPos)
	self:disconnectMoveToConnection()
	self.humanoidMoveToFinishedConnection = self.character.Humanoid.MoveToFinished:Connect(function()
		self:onMoveToFinished()
	end)

	self.character.Humanoid:MoveTo(self.waypoints[self.currentWaypointIndex].Position)
end

function PathNavigation.onMoveToFinished(self: PathNavigation): ()
	self.currentWaypointIndex += 1 -- move to the next waypoint first
	local currentWaypointIndex = self.currentWaypointIndex
	local waypoints = self.waypoints

	if currentWaypointIndex > #waypoints then
		self.finished = true
		self:disconnectMoveToConnection()
		return
	end

	self.character.Humanoid:MoveTo(waypoints[currentWaypointIndex].Position)
end

function PathNavigation.stop(self: PathNavigation)
	self.path = nil
	self:disconnectMoveToConnection()

	local lastSpeed = self.character.Humanoid.WalkSpeed
	self.character.Humanoid.WalkSpeed = 0
	-- move to its current position to stop moving
	self.character.Humanoid:MoveTo(self.character.HumanoidRootPart.Position)
	self.character.Humanoid.WalkSpeed = lastSpeed
end

return PathNavigation