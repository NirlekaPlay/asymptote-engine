--!strict

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollisionGroupBuilder = require(ServerScriptService.server.physics.collision.CollisionGroupBuilder)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)

--[=[
	@class CollisionGroupManager

	Registers and manages all collision groups.
]=]
local CollisionGroupManager = {}

function CollisionGroupManager.register()
	CollisionGroupManager.registerCollisionGroupsFromDict(CollisionGroupTypes :: any)

	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER, CollisionGroupTypes.PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.PLAYER, CollisionGroupTypes.PLAYER, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.BLOCK_VISION_RAYCAST, true)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.IGNORE_VISION_RAYCAST, false)
	PhysicsService:CollisionGroupSetCollidable(CollisionGroupTypes.VISION_RAYCAST, CollisionGroupTypes.PATHFINDING_BLOCKER, false)

	CollisionGroupBuilder.new(CollisionGroupTypes.BULLET)
		:notCollideWith(CollisionGroupTypes.PLAYER_COLLIDER)
		:notCollideWith(CollisionGroupTypes.PATHFINDING_PART)
		:notCollideWith(CollisionGroupTypes.BULLET)
		:register()

	CollisionGroupBuilder.new(CollisionGroupTypes.PATHFINDING_BLOCKER)
		:notCollideWithAnything()
		:register()

	CollisionGroupBuilder.new(CollisionGroupTypes.CLIENT_TARGET_OBSTRUCTED_RAY)
		:notCollideWith(CollisionGroupTypes.PATHFINDING_PART)
		:notCollideWith(CollisionGroupTypes.BULLET)
		:register()
end

function CollisionGroupManager.registerCollisionGroupsFromDict(collisionGroups: { [any]: string }): ()
	for _, collisionGroupName in collisionGroups do
		if not PhysicsService:IsCollisionGroupRegistered(collisionGroupName) then
			PhysicsService:RegisterCollisionGroup(collisionGroupName)
		end
	end
end

return CollisionGroupManager