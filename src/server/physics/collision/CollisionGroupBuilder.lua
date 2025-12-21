--!strict

local PhysicsService = game:GetService("PhysicsService")

--[=[
	@class CollisionGroupBuilder

	Registers collision groups using the builder pattern.
]=]
local CollisionGroupBuilder = {}
CollisionGroupBuilder.__index = CollisionGroupBuilder

export type CollisionGroupBuilder = typeof(setmetatable({} :: {
	collisionGroupName: string
}, CollisionGroupBuilder))

function CollisionGroupBuilder.new(groupName: string): CollisionGroupBuilder
	return setmetatable({
		collisionGroupName = groupName
	}, CollisionGroupBuilder)
end

function CollisionGroupBuilder.collidesWith(self: CollisionGroupBuilder, otherGroupName: string): CollisionGroupBuilder
	PhysicsService:CollisionGroupSetCollidable(self.collisionGroupName, otherGroupName, true)
	return self
end

function CollisionGroupBuilder.notCollideWith(self: CollisionGroupBuilder, otherGroupName: string): CollisionGroupBuilder
	PhysicsService:CollisionGroupSetCollidable(self.collisionGroupName, otherGroupName, false)
	return self
end

function CollisionGroupBuilder.notCollideWithAnything(self: CollisionGroupBuilder): CollisionGroupBuilder
	for _, v in PhysicsService:GetRegisteredCollisionGroups() do
		-- roblox didnt correctly type annotated what
		PhysicsService:CollisionGroupSetCollidable(v.name :: string, self.collisionGroupName, false)
	end
	return self
end

function CollisionGroupBuilder.notCollideWithAnythingButSelf(self: CollisionGroupBuilder): CollisionGroupBuilder
	for _, v in PhysicsService:GetRegisteredCollisionGroups() do
		if v.name ~= self.collisionGroupName then
			PhysicsService:CollisionGroupSetCollidable(v.name :: string, self.collisionGroupName, false)
		end
	end
	return self
end

function CollisionGroupBuilder.register(self: CollisionGroupBuilder): ()
	if not PhysicsService:IsCollisionGroupRegistered(self.collisionGroupName) then
		PhysicsService:RegisterCollisionGroup(self.collisionGroupName)
	end
end

return CollisionGroupBuilder