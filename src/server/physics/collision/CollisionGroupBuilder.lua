--!strict

local PhysicsService = game:GetService("PhysicsService")

local function getRegisteredCollisionGroupsArray(): { string }
	local t: { string } = {}

	for i, v in PhysicsService:GetRegisteredCollisionGroups() do
		-- Roblox didnt correctly type annotated it, what
		t[i] = v.name
	end

	return t
end

--[=[
	@class CollisionGroupBuilder

	Registers collision groups using the builder pattern.
]=]
local CollisionGroupBuilder = {}
CollisionGroupBuilder.__index = CollisionGroupBuilder

export type CollisionGroupBuilder = typeof(setmetatable({} :: {
	collisionGroupName: string,
	collisionDict: {
		[string]: boolean
	}
}, CollisionGroupBuilder))

function CollisionGroupBuilder.new(groupName: string): CollisionGroupBuilder
	return setmetatable({
		collisionGroupName = groupName,
		collisionDict = {}
	}, CollisionGroupBuilder)
end

function CollisionGroupBuilder.collidesWith(self: CollisionGroupBuilder, otherGroupName: string): CollisionGroupBuilder
	self.collisionDict[otherGroupName] = true
	return self
end

function CollisionGroupBuilder.notCollideWith(self: CollisionGroupBuilder, otherGroupName: string): CollisionGroupBuilder
	self.collisionDict[otherGroupName] = false
	return self
end

function CollisionGroupBuilder.notCollideWithSelf(self: CollisionGroupBuilder): CollisionGroupBuilder
	self.collisionDict[self.collisionGroupName] = false
	return self
end

function CollisionGroupBuilder.notCollideWithAnything(self: CollisionGroupBuilder): CollisionGroupBuilder
	for _, collisionGroupName in getRegisteredCollisionGroupsArray() do
		self.collisionDict[collisionGroupName] = false
	end
	for collisionGroupName in self.collisionDict do
		self.collisionDict[collisionGroupName] = false
	end
	return self
end

function CollisionGroupBuilder.notCollideWithAnythingButSelf(self: CollisionGroupBuilder): CollisionGroupBuilder
	for _, collisionGroupName in getRegisteredCollisionGroupsArray() do
		if collisionGroupName ~= self.collisionGroupName then
			self.collisionDict[collisionGroupName] = false
		else
			self.collisionDict[collisionGroupName] = true
		end
	end
	for collisionGroupName in self.collisionDict do
		if collisionGroupName ~= self.collisionGroupName then
			self.collisionDict[collisionGroupName] = false
		else
			self.collisionDict[collisionGroupName] = true
		end
	end
	return self
end

function CollisionGroupBuilder.register(self: CollisionGroupBuilder): ()
	if not PhysicsService:IsCollisionGroupRegistered(self.collisionGroupName) then
		PhysicsService:RegisterCollisionGroup(self.collisionGroupName)
	end

	for collisionGroupName, doesCollide in self.collisionDict do
		if not PhysicsService:IsCollisionGroupRegistered(collisionGroupName) then
			PhysicsService:RegisterCollisionGroup(collisionGroupName)
		end

		PhysicsService:CollisionGroupSetCollidable(self.collisionGroupName, collisionGroupName, doesCollide)
	end
end

return CollisionGroupBuilder