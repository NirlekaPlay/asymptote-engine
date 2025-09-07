--!strict

local HTTPService = game:GetService("HttpService")

export type StaticEntity = {
	uuid: string,
	name: string,
	isStatic: true,
	position: Vector3
}

export type DynamicEntity = {
	uuid: string,
	name: string,
	isStatic: false,
	instance: Instance
}

--[=[
	@class EntityManager
]=]
local EntityManager = {
	Entities = {} :: { [string]: StaticEntity | DynamicEntity }
}

function EntityManager.newStatic(name: string, position: Vector3, uuid: string?): string
	local entityUID = uuid or HTTPService:GenerateGUID(false)
	local entity: StaticEntity = {
		uuid = entityUID,
		name = name,
		position = position,
		isStatic = true :: true,
		statuses = {}
	}
	
	EntityManager.Entities[entityUID] = entity
	return entityUID
end

function EntityManager.newDynamic(name: string, instance: Instance, uuid: string?): string
	local entityUID = uuid or HTTPService:GenerateGUID(false)
	local entity: DynamicEntity = {
		uuid = entityUID,
		name = name,
		instance = instance,
		isStatic = false :: false,
		statuses = {}
	}
	
	EntityManager.Entities[entityUID] = entity
	return entityUID
end

function EntityManager.getEntityByUuid(entityUuid: string): StaticEntity | DynamicEntity
	return EntityManager.Entities[entityUuid]
end

return EntityManager
