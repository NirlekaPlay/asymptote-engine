--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PatrolState = require(ServerScriptService.server.ai.behavior.patrol.PatrolState)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)

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
	VISIBLE_PLAYERS = register("visible_players") :: MemoryModuleType< { [Player]: true } >,
	HEARABLE_PLAYERS = register("hearable_players") :: MemoryModuleType< { [Player]: true } >,
	LOOK_TARGET = register("look_target") :: MemoryModuleType<Player>,
	KILL_TARGET = register("kill_target") :: MemoryModuleType<Player>,
	FOLLOW_TARGET = register("follow_target") :: MemoryModuleType<Player>,
	PANIC_PLAYER_SOURCE = register("panic_player_source") :: MemoryModuleType<Player>,
	TARGET_POST = register("target_post") :: MemoryModuleType<GuardPost.GuardPost>,
	DESIGNATED_POSTS = register("designated_posts") :: MemoryModuleType<{GuardPost.GuardPost}>,
	PATROL_STATE = register("patrol_state") :: MemoryModuleType<PatrolState.PatrolState>,
	POST_VACATE_COOLDOWN = register("post_vacate_cooldown") :: MemoryModuleType<number>,
	IS_CURIOUS = register("is_curious") :: MemoryModuleType<boolean>,
	IS_PANICKING = register("is_panicking") :: MemoryModuleType<boolean>,
	IS_FLEEING = register("is_fleeing") :: MemoryModuleType<boolean>,
	IS_INTIMIDATED = register("is_intimidated") :: MemoryModuleType<boolean>,
	HAS_FLED = register("has_fled") :: MemoryModuleType<true>,
	PANIC_POSITION = register("panic_position") :: MemoryModuleType<Vector3>,
	FLEE_TO_POSITION = register("flee_to_position") :: MemoryModuleType<Vector3>,
	CONFRONTING_TRESPASSER = register("confronting_trespasser") :: MemoryModuleType<Player>,
	SPOTTED_TRESPASSER = register("spotted_trespasser") :: MemoryModuleType<Player>,
	TRESPASSERS_WARNS = register("trespassers_warns") :: MemoryModuleType<{ [Player]: number }>,
	REPORTING_ON = register("reporting_on") :: MemoryModuleType<string>,
	VISISBLE_C4 = register("visible_c4") :: MemoryModuleType< { [string]: true } >,
}

return MemoryModuleTypes