--!strict

--[=[
	@class PrioritizedEntity
]=]
local PrioritizedEntity = {}
PrioritizedEntity.__index = PrioritizedEntity

export type PrioritizedEntity = typeof(setmetatable({} :: {
	entityUuid: string,
	forStatus: string
}, PrioritizedEntity))

function PrioritizedEntity.new(entityUuid: string, forStatus: string): PrioritizedEntity
	return setmetatable({
		entityUuid = entityUuid,
		forStatus = forStatus
	}, PrioritizedEntity)
end

function PrioritizedEntity.getStatus(self: PrioritizedEntity): string
	return self.forStatus
end

function PrioritizedEntity.getUuid(self: PrioritizedEntity): string
	return self.entityUuid
end

return PrioritizedEntity