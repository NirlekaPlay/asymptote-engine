--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DetectionDummy = require(ServerScriptService.server.npc.dummies.DetectionDummy)
local Entity = require(ServerScriptService.server.world.entity.Entity)
local LevelAccessor = require(ReplicatedStorage.shared.world.level.LevelAccessor)

--[=[
	@class EntityType
]=]
local EntityType = {}

export type EntityType<T> = {
	create: (level: LevelAccessor.LevelAccessor) -> Entity.Entity & T
}

local registryByNames: { [string]: EntityType<any> } = {}

local function register<T>(factory: (level: LevelAccessor.LevelAccessor) -> T, name: string): EntityType<T>
	local entityType = {
		create = factory
	}

	registryByNames[name] = entityType

	return entityType
end

function EntityType.getEntityTypeByName(name: string): EntityType<Entity.Entity>?
	return registryByNames[name]
end

EntityType.NPC = register(function(level)
	local clonedChar = ReplicatedStorage.shared.assets.characters.Rig:Clone()
	return DetectionDummy.new(level, level, clonedChar)
end, "npc")

return EntityType