--!strict

local EntityType = require(script.Parent.EntityType)

export type Entity = {
	getInstance: (self: Entity) -> Instance,
	getPosition: (self: Entity) -> Vector3,
	getEntityType: (self: Entity) -> EntityType.EntityType<any>
}

return nil