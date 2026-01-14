--!strict

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollisionGroupBuilder = require(ServerScriptService.server.physics.collision.CollisionGroupBuilder)
local CollisionGroupRegistry = require(ServerScriptService.server.physics.collision.CollisionGroupRegistry)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)

--[=[
	@class CollisionGroupManager

	Registers and manages all collision groups.
]=]
local CollisionGroupManager = {}

function CollisionGroupManager.register()
	CollisionGroupRegistry.registerCollisionGroupsFromDict(CollisionGroupTypes :: any)

	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, CollisionGroupTypes.PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.PLAYER, CollisionGroupTypes.PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.BLOCK_VISION_RAYCAST, true)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.IGNORE_VISION_RAYCAST, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.PATHFINDING_BLOCKER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.BULLET, CollisionGroupTypes.PLAYER_COLLIDER, false)

	CollisionGroupBuilder.new(CollisionGroupTypes.PATHFINDING_BLOCKER)
		:notCollideWithAnything()
		:register()

	CollisionGroupBuilder.new(CollisionGroupTypes.CLIENT_TARGET_OBSTRUCTED_RAY)
		:notCollideWith(CollisionGroupTypes.PATHFINDING_PART)
		:notCollideWith(CollisionGroupTypes.BULLET)
		:register()
end

return CollisionGroupManager