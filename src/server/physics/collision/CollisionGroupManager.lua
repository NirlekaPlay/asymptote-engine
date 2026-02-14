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

	CollisionGroupBuilder.new(CollisionGroupTypes.NPC_CHAR)
		:notCollideWith(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER)
		:notCollideWith(CollisionGroupTypes.PLAYER)
		:notCollideWithSelf()
		:collidesWith(CollisionGroupTypes.QUERY_CHECK_NPC_CHARS)
		:register()
	
	CollisionGroupBuilder.new(CollisionGroupTypes.QUERY_CHECK_NPC_CHARS)
		:notCollideWithAnything()
		:collidesWith(CollisionGroupTypes.NPC_CHAR)
		:register()

	CollisionGroupBuilder.new(CollisionGroupTypes.BODY_DRAG_RAGDOLL)
		:collidesWithSelf()
		:notCollideWith(CollisionGroupTypes.PLAYER)
		:notCollideWith(CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER)
		:register()

	CollisionGroupBuilder.new(CollisionGroupTypes.CLIENT_CAMERA_OCCLUSION_RAY)
		:notCollideWith(CollisionGroupTypes.BODY_DRAG_RAGDOLL)
		:notCollideWith(CollisionGroupTypes.RAGDOLL_COLLIDER_PART)
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