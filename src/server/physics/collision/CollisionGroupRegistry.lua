--!strict

local PhysicsService = game:GetService("PhysicsService")

--[=[
	@class CollisionGroupRegistry
]=]
local CollisionGroupRegistry = {}

function CollisionGroupRegistry.createBuilder()
	
end

function CollisionGroupRegistry.registerCollisionGroupsFromDict(collisionGroups: { [any]: string }): ()
	for _, collisionGroupName in collisionGroups do
		if not PhysicsService:IsCollisionGroupRegistered(collisionGroupName) then
			PhysicsService:RegisterCollisionGroup(collisionGroupName)
		end
	end
end

function CollisionGroupRegistry.getCollisionGroupRelationships(): { [string]: { [string]: boolean } }
	local registeredCollisionGroups = PhysicsService:GetRegisteredCollisionGroups()
	local collisionGroupNamesSet = table.create(#registeredCollisionGroups) :: { [string]: true }

	for i, collisionGroup in registeredCollisionGroups do
		collisionGroupNamesSet[collisionGroup.name] = true
	end

	local relationships: { [string]: { [string]: boolean } } = {}

	for groupA_Name, _ in pairs(collisionGroupNamesSet) do
		local nestedRelationships: { [string]: boolean } = {}
		
		for groupB_Name, _ in pairs(collisionGroupNamesSet) do
			local areCollidable = PhysicsService:CollisionGroupsAreCollidable(groupA_Name, groupB_Name)
			nestedRelationships[groupB_Name] = areCollidable
		end

		relationships[groupA_Name] = nestedRelationships
	end

	return relationships
end

return CollisionGroupRegistry