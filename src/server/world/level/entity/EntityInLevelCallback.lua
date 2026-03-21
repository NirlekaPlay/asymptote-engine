--!strict

export type EntityInLevelCallback = {
	onMove: (self: any) -> (),
	onRemove: (self: any, removalReason: RemovalReason) -> ()
}

type RemovalReason = number -- HACK WARNING: Duplicate from Entity.RemovalReason, to prevent fucking circular dependency

local NULL: EntityInLevelCallback = {
	onMove = function(_)
		return
	end,
	onRemove = function(_, _)
		return
	end
}

return {
	NULL = NULL
}