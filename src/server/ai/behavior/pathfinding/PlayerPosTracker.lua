--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PositionTracker = require(ServerScriptService.server.ai.behavior.pathfinding.PositionTracker)

--[=[
	@class PlayerPosTracker
]=]
local PlayerPosTracker = {}
PlayerPosTracker.__index = PlayerPosTracker

export type PlayerPosTracker = PositionTracker.PositionTracker & typeof(setmetatable({} :: {
	player: Player,
	lastPos: Vector3
}, PlayerPosTracker))

function PlayerPosTracker.new(player: Player): PlayerPosTracker
	return setmetatable({
		player = player,
		lastPos = Vector3.zero -- ???
	}, PlayerPosTracker) :: PlayerPosTracker
end

function PlayerPosTracker.getCurrentPosition(self: PlayerPosTracker): Vector3
	local character = self.player.Character
	if not character then
		return self.lastPos -- Return the last known position if character is missing
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	-- Check if the player is alive and has a physical body
	if rootPart and humanoid and humanoid.Health > 0 then
		self.lastPos = rootPart.Position
		return self.lastPos
	end

	return self.lastPos
end

function PlayerPosTracker.getBlockPosition(self: PlayerPosTracker): Vector3
	local currentPos = self:getCurrentPosition()
	return Vector3.new(
		math.floor(currentPos.X),
		math.floor(currentPos.Y - 2),
		math.floor(currentPos.Z)
	)
end

return PlayerPosTracker