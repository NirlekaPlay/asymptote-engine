--!strict

local PathfindingService = game:GetService("PathfindingService")
local ServerScriptService = game:GetService("ServerScriptService")
local RblxAgentParameters = require(ServerScriptService.server.ai.navigation.RblxAgentParameters)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

--[=[
	@class PathNavigation
]=]
local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type PathNavigation = typeof(setmetatable({} :: {
	path: NodePath.NodePath?,
	rblxPath: Path,
	humanoid: Humanoid,
	character: Model,
	--
	currentMoveToThread: thread?,
	moveToFinishedConn: RBXScriptConnection?,
}, PathNavigation))

function PathNavigation.new(character: Model, agentParams: RblxAgentParameters.AgentParameters): PathNavigation
	return setmetatable({
		path = nil :: NodePath.NodePath?,
		rblxPath = PathfindingService:CreatePath(agentParams :: any),
		humanoid = (character :: any).Humanoid :: Humanoid,
		character = character,
		--
		currentMoveToThread = nil :: thread?,
		moveToFinishedConn = nil :: RBXScriptConnection?
	}, PathNavigation)
end

function PathNavigation.isMoving(self: PathNavigation): boolean
	return self.path ~= nil
end

function PathNavigation.moveToPos(self: PathNavigation, pos: Vector3, minDist: number): ()
	if self.currentMoveToThread then
		task.cancel(self.currentMoveToThread)
		self:stop()
	end

	self.currentMoveToThread = task.spawn(function()
		local path = self.rblxPath
		if not path then
			error("ERR_NO_PATH")
		end
		
		local success, errorMessage = pcall(function()
			return path:ComputeAsync(self:getCharacterPosition(), pos)
		end)
		
		if success and path.Status == Enum.PathStatus.Success then
			local nodePath = NodePath.new(path:GetWaypoints(), pos, 1)
			self.path = nodePath
			nodePath:advance()
			self.moveToFinishedConn = self.humanoid.MoveToFinished:Connect(function(reached)
				self:onMoveToFinished(reached)
			end)
			self:humanoidMoveToPos(nodePath:getNextNode().Position)
		else
			warn("Pathfinding failed:", errorMessage)
			self:stop()
		end
	end)
end

function PathNavigation.stop(self: PathNavigation): ()
	self:disconnectOnMoveToFinishedConnection()
	self.path = nil
end

function PathNavigation.getCharacterPosition(self: PathNavigation): Vector3
	local char = self.character
	if not char then
		error("ERR_NO_CHAR")
	end

	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoidRootPart then
		error("ERR_NO_HUMANOID_ROOT_PART")
	end

	return humanoidRootPart.Position
end

--

function PathNavigation.onMoveToFinished(self: PathNavigation, reached: boolean): ()
	if self.path == nil then
		self:disconnectOnMoveToFinishedConnection()
		return
	end

	if not reached then
		warn("Failed to reach waypoint")
		self:stop()
		return
	end

	if not self.path:isDone() then
		self.path:advance()
		local nextNode = self.path:getNextNode()

		self:humanoidMoveToPos(nextNode.Position)

		if nextNode.Action == Enum.PathWaypointAction.Jump then
			self.humanoid.Jump = true
		end
	else
		print("Path complete")
		self:stop()
	end
end

function PathNavigation.disconnectOnMoveToFinishedConnection(self: PathNavigation): ()
	if self.moveToFinishedConn then
		self.moveToFinishedConn:Disconnect()
	end
end

function PathNavigation.humanoidMoveToPos(self: PathNavigation, pos: Vector3): ()
	self.humanoid:MoveTo(pos)
end

return PathNavigation