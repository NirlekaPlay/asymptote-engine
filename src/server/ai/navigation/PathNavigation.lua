--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SimplePath = require(ReplicatedStorage.shared.thirdparty.SimplePath)

local DIST_THRESHOLD = 3

local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type PathNavigation = typeof(setmetatable({} :: {
	pathfinder: SimplePath.SimplePath,
	reachedConnection: RBXScriptConnection?,
	pathConnections: { [string]: RBXScriptConnection },
	finished: boolean
}, PathNavigation))

type AgentParameters = SimplePath.AgentParameters

function PathNavigation.new(character: Model, agentParams: AgentParameters?): PathNavigation
	return setmetatable({
		pathfinder = SimplePath.new(character, agentParams),
		reachedConnection = nil :: RBXScriptConnection?,
		pathConnections = {},
		finished = false
	}, PathNavigation)
end

function PathNavigation.getPath(self: PathNavigation): Path
	return (self.pathfinder :: SimplePath.SimplePathInternal)._path
end

function PathNavigation.moveTo(self: PathNavigation, toPos: Vector3): ()
	self:stop()

	--[[if (self.pathfinder :: SimplePath.SimplePathInternal)._agent.Name == "Bob" then
		local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
		warn("Attempt to move to", toPos)
		Draw.point(toPos)
	end]]

	local character = (self.pathfinder :: SimplePath.SimplePathInternal)._agent
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		warn("PathNavigation: character missing HumanoidRootPart")
		return
	end

	local currentPos = rootPart.Position
	local distance = (currentPos - toPos).Magnitude

	--warn("distance:", distance)

	if distance < DIST_THRESHOLD then
		self.finished = true
		return
	end

	self.pathfinder:Run(toPos)

	if not self.pathConnections["err"] then
		self.pathConnections["err"] = self.pathfinder.Error:Connect(function(...)
			warn("What?! Looks like pathfinding threw an error for:", ...)
		end)
	end

	if not self.pathConnections["blocked"] then
		self.pathConnections["blocked"] = self.pathfinder.Blocked:Connect(function(model, waypoint)
			warn("Hmm.. Looks like pathfinding got blocked for", model:GetFullName(), "for waypoint:", waypoint)
		end)
	end

	self.reachedConnection = self.pathfinder.Reached:Once(function()
		self.finished = true
	end)
end

function PathNavigation.isMoving(self: PathNavigation): boolean
	return self.pathfinder.Status == "Active"
end

function PathNavigation.stop(self: PathNavigation)
	self:disconnectAndClearConnections()
	self.finished = false
	if self.pathfinder.Status == "Active" then
		self.pathfinder:Stop()
	end
end

function PathNavigation.disconnectAndClearConnections(self: PathNavigation): ()
	if self.reachedConnection then
		self.reachedConnection:Disconnect()
		self.reachedConnection = nil
	end

	for name, connection in pairs(self.pathConnections) do
		connection:Disconnect()
		self.pathConnections[name] = nil
	end
end

return PathNavigation