--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PatrolState = require(ServerScriptService.server.ai.behavior.patrol.PatrolState)
local PrioritizedEntity = require(ServerScriptService.server.ai.memory.PrioritizedEntity)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

--[=[
	@class MemoryModuleTypes

	For typechecking purposes.
]=]
export type MemoryModuleType<T> = {
	name: string
}

local function register<T>(name: string): MemoryModuleType<T>
	return {
		name = name,
	}
end

local MemoryModuleTypes = {
	ATTENTION_LEVEL = register("attention_level") :: MemoryModuleType<any>,
	VISIBLE_ENTITIES = register("visible_entities") :: MemoryModuleType< { [string]: true }>,
	VISIBLE_PLAYERS = register("visible_players") :: MemoryModuleType< { [Player]: true } >,
	HEARABLE_PLAYERS = register("hearable_players") :: MemoryModuleType< { [Player]: true } >,
	TARGETABLE_ENTITIES = register("targetable_entities") :: MemoryModuleType< { [Player]: true }>,
	LOOK_TARGET = register("look_target") :: MemoryModuleType<string>,
	KILL_TARGET = register("kill_target") :: MemoryModuleType<Player>,
	WALK_TARGET = register("walk_target") :: MemoryModuleType<WalkTarget.WalkTarget>,
	PATH = register("path") :: MemoryModuleType<NodePath.NodePath>,
	CANT_REACH_WALK_TARGET_SINCE = register("cant_reach_walk_target_since") :: MemoryModuleType<number>,
	PANIC_SOURCE_ENTITY_UUID = register("panic_source_entity_uuid"):: MemoryModuleType<string>,
	CURRENT_POST = register("current_post") :: MemoryModuleType<Node.Node>,
	TARGET_POST = register("target_post") :: MemoryModuleType<Node.Node>,
	DESIGNATED_POSTS = register("designated_posts") :: MemoryModuleType<{Node.Node}>,
	PATROL_STATE = register("patrol_state") :: MemoryModuleType<PatrolState.PatrolState>,
	PRIORITIZED_ENTITY = register("prioritized_entity") :: MemoryModuleType<PrioritizedEntity.PrioritizedEntity>,
	POST_VACATE_COOLDOWN = register("post_vacate_cooldown") :: MemoryModuleType<number>,
	IS_COMBAT_MODE = register("is_combat_mode") :: MemoryModuleType<boolean>,
	IS_CURIOUS = register("is_curious") :: MemoryModuleType<boolean>,
	IS_PANICKING = register("is_panicking") :: MemoryModuleType<boolean>,
	IS_FLEEING = register("is_fleeing") :: MemoryModuleType<boolean>,
	IS_INVESTIGATING = register("is_investigating") :: MemoryModuleType<boolean>,
	IS_INTIMIDATED = register("is_intimidated") :: MemoryModuleType<boolean>,
	HAS_FLED = register("has_fled") :: MemoryModuleType<true>,
	HAS_RETREATED = register("has_retreated") :: MemoryModuleType<true>,
	PANIC_POSITION = register("panic_position") :: MemoryModuleType<Vector3>,
	FLEE_TO_POSITION = register("flee_to_position") :: MemoryModuleType<Vector3>,
	CONFRONTING_TRESPASSER = register("confronting_trespasser") :: MemoryModuleType<Player>,
	TRESPASSERS_WARNS = register("trespassers_warns") :: MemoryModuleType<{ [string]: number }>,
	TRESPASSERS_ENCOUNTERS = register("trespassers_encounters") :: MemoryModuleType<{ [string]: number }>,
	REPORTING_ON = register("reporting_on") :: MemoryModuleType<string>,
	VISISBLE_C4 = register("visible_c4") :: MemoryModuleType< { [string]: true } >,
}

return MemoryModuleTypes