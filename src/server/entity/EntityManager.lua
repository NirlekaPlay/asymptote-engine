--!strict

local HTTPService = game:GetService("HttpService")

--[=[
	@class EntityManager

	Prototype written by @Crafterinooo.
]=]



export type StaticEntity = {
	name: string,
	isStatic: true,
	position: Vector3,
}

export type DynamicEntity = {
	name: string,
	isStatic: false,
	instance: Instance,
}

export type Entity = (StaticEntity | DynamicEntity)

local EntityManager = {
	Entities = {} :: { [string]: Entity }
}

function EntityManager.newStatic(name: string, position: Vector3): string
	local entityUID = HTTPService:GenerateGUID(false)
	local entity: Entity = {
		name = name,
		position = position,
		isStatic = true :: true,
	}
	
	EntityManager.Entities[entityUID] = entity
	return entityUID
end

function EntityManager.newDynamic(name: string, instance: Instance): string
	local entityUID = HTTPService:GenerateGUID(false)
	local entity: Entity = {
		name = name,
		instance = instance,
		isStatic = false :: false,
	}
	
	EntityManager.Entities[entityUID] = entity
	return entityUID
end

return EntityManager
