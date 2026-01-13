--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MoveControl = require(ServerScriptService.server.ai.control.MoveControl)
local RblxAgentParameters = require(ServerScriptService.server.ai.navigation.RblxAgentParameters)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

local DEFAULT_SPEED_MODIFIER = 1

--[=[
	@class PathNavigation
]=]
local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type PathNavigation = typeof(setmetatable({} :: {
	moveControl: MoveControl.MoveControl,
	path: NodePath.NodePath?,
	rblxPath: Path,
	humanoid: Humanoid,
	character: Model,
	speedModifier: number,
	--
	currentMoveToThread: thread?,
	moveToFinishedConn: RBXScriptConnection?,
}, PathNavigation))

function PathNavigation.new(
	character: Model,
	moveControl: MoveControl.MoveControl,
	agentParams: RblxAgentParameters.AgentParameters
): PathNavigation
	return setmetatable({
		moveControl = moveControl,
		path = nil :: NodePath.NodePath?,
		rblxPath = PathfindingService:CreatePath(agentParams :: any),
		humanoid = (character :: any).Humanoid :: Humanoid,
		character = character,
		speedModifier = DEFAULT_SPEED_MODIFIER,
		--
		currentMoveToThread = nil :: thread?,
		moveToFinishedConn = nil :: RBXScriptConnection?
	}, PathNavigation)
end

function PathNavigation.isMoving(self: PathNavigation): boolean
	return self.path ~= nil
end

function PathNavigation.isDone(self: PathNavigation): boolean
	return self.path == nil or self.path:isDone()
end

function PathNavigation.getPath(self: PathNavigation): NodePath.NodePath?
	return self.path
end

function PathNavigation.setSpeedModifier(self: PathNavigation, speedModifier: number): ()
	self.speedModifier = speedModifier
end

function PathNavigation.createPathAsync(self: PathNavigation, pos: Vector3): NodePath.NodePath?
	local path = self.rblxPath
	if not path then
		error("ERR_NO_PATH")
	end
	
	local success: boolean, errorMessage: string = (pcall :: any)(function()
		path:ComputeAsync(self:getCharacterPosition(), pos)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		return NodePath.new(path:GetWaypoints(), pos, 1)
	else
		warn("Pathfinding failed:", errorMessage)
		return nil
	end
end

function PathNavigation.moveToPos(self: PathNavigation, pos: Vector3, speedModifier: number?): ()
	if self.currentMoveToThread ~= nil then
		task.cancel(self.currentMoveToThread)
		self:stop()
	end

	self.currentMoveToThread = task.spawn(function()
		local nodePath = self:createPathAsync(pos)
		self.currentMoveToThread = nil
		if nodePath then
			self:moveToFromPath(nodePath, speedModifier)
		else
			self:stop()
		end
	end)
end

function PathNavigation.moveToFromPath(self: PathNavigation, path: NodePath.NodePath?, speedModifier: number?): boolean
	if self.currentMoveToThread ~= nil then
		task.cancel(self.currentMoveToThread)
		self:stop()
	end

	if path == nil then
		self:stop()
		return false
	end
	
	self.path = path
	self.speedModifier = speedModifier or DEFAULT_SPEED_MODIFIER -- TODO: May cause problems. Idk why but it may.
	path:advance()
	self.moveToFinishedConn = self.humanoid.MoveToFinished:Connect(function(reached)
		self:onMoveToFinished(reached)
	end)
	
	self:reclaimCharNetworkOwner()
	self.moveControl:setWantedPosition(path:getNextNode().Position, self.speedModifier)

	return true
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

		self:reclaimCharNetworkOwner()
		self.moveControl:setWantedPosition(nextNode.Position, self.speedModifier)

		if nextNode.Action == Enum.PathWaypointAction.Jump then
			self.humanoid.Jump = true
		end
	else
		self:stop()
	end
end

function PathNavigation.disconnectOnMoveToFinishedConnection(self: PathNavigation): ()
	if self.moveToFinishedConn then
		self.moveToFinishedConn:Disconnect()
		self.moveToFinishedConn = nil
	end
end

function PathNavigation.reclaimCharNetworkOwner(self: PathNavigation): ()
	-- Prevents janky movements by the parts of the character to have network owner of a player
	-- We don't know the exact performance impact of GetChildren()
	-- So leave this for now.
	for _, child in self.character:GetChildren() do
		if child:IsA("BasePart") and child:GetNetworkOwner() ~= nil then
			child:SetNetworkOwner(nil)
		end
	end
end

return PathNavigation