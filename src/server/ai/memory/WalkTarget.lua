--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PlayerPosTracker = require(ServerScriptService.server.ai.behavior.pathfinding.PlayerPosTracker)
local PositionTracker = require(ServerScriptService.server.ai.behavior.pathfinding.PositionTracker)
local Vec3PosTracker = require(ServerScriptService.server.ai.behavior.pathfinding.Vec3PosTracker)

--[=[
	@class WalkTarget
]=]
local WalkTarget = {}
WalkTarget.__index = WalkTarget

export type WalkTarget = typeof(setmetatable({} :: {
	target: PositionTracker.PositionTracker,
	speedModifier: number,
	closeEnoughDist: number
}, WalkTarget))

function WalkTarget.new(
	target: PositionTracker.PositionTracker,
	speedModifier: number,
	closeEnoughDist: number
): WalkTarget
	return setmetatable({
		target = target,
		speedModifier = speedModifier,
		closeEnoughDist = closeEnoughDist
	}, WalkTarget)
end

function WalkTarget.fromVector3(pos: Vector3, speedModifier: number, minDist: number): WalkTarget
	return WalkTarget.new(Vec3PosTracker.new(pos), speedModifier, minDist)
end

function WalkTarget.fromPlayer(entity: Player, speedModifier: number, minDist: number): WalkTarget
	return WalkTarget.new(PlayerPosTracker.new(entity), speedModifier, minDist)
end

function WalkTarget.getTarget(self: WalkTarget): PositionTracker.PositionTracker
	return self.target
end

function WalkTarget.getSpeedModifier(self: WalkTarget): number
	return self.speedModifier
end

function WalkTarget.getCloseEnoughDist(self: WalkTarget): number
	return self.closeEnoughDist
end

return WalkTarget