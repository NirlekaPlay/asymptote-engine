--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectableEntity = require(ServerScriptService.server.ai.detection.entity.DetectableEntity)

--[=[
	@class PlayerDetectableEntity
]=]
local PlayerDetectableEntity = {}
PlayerDetectableEntity.__index = PlayerDetectableEntity

export type PlayerDetectableEntity = typeof(setmetatable({} :: {
	uuid: string,
	player: Player,
}, PlayerDetectableEntity)) & DetectableEntity.DetectableEntity

function PlayerDetectableEntity.new(player: Player): PlayerDetectableEntity	
	return setmetatable({
		player = player,
	}, PlayerDetectableEntity) :: PlayerDetectableEntity
end

function PlayerDetectableEntity.getUuid(self: PlayerDetectableEntity): string
	return self.uuid
end

function PlayerDetectableEntity.getPosition(self: PlayerDetectableEntity): Vector3
	return ((self.player.Character :: any).HumanoidRootPart :: BasePart).Position
end

function PlayerDetectableEntity.getBasePriority(self: PlayerDetectableEntity): number
	return 1.0
end

function PlayerDetectableEntity.getPriority(self: PlayerDetectableEntity): number
	return self:getBasePriority() * self:getMovementMultiplier()
end

function PlayerDetectableEntity.getDetectionMultiplier(self: PlayerDetectableEntity): number
	return 1.0
end

function PlayerDetectableEntity.getMovementMultiplier(self: PlayerDetectableEntity): number
	local character = self.player.Character
	local velocity = ((character :: any).HumanoidRootPart :: BasePart).AssemblyLinearVelocity.Magnitude
	return 1 + (velocity / 16)
end

return PlayerDetectableEntity