--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SimplePath = require(ReplicatedStorage.shared.thirdparty.SimplePath)

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
	self.pathfinder:Run(toPos)
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