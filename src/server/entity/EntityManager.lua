--!strict

local HTTPService = game:GetService("HttpService")

export type EntityType = "DANGER" | "SAFE"

export type Entity = {
	name: string,
	position: Vector3,
	entityType: string,
	instance: Instance?,
}

local EntityManager = {
	Entities = {} :: { [string]: Entity }
}

--[=[
	@class EntityManager

	Prototype written by @Crafterinoo.
]=]
function EntityManager.new(name: string, position: Vector3, entityType: EntityType, instance: Instance?): string
	local entityUID = HTTPService:GenerateGUID(false)
	local entity = {}
	
	entity.name = name
	entity.position = position
	entity.entityType = entityType
	
	if instance then
		entity.instance = instance
	end
	
	assert(entity.name, "No Entityname given")
	assert(entity.position, "No Entityposition given")
	assert(entity.entityType, "No Entitytype given")
	
	EntityManager.Entities[entityUID] = entity

	return entityUID
end

return EntityManager
