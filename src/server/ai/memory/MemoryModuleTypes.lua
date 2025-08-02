--!strict
local ServerScriptService = game:GetService("ServerScriptService")

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
	TARGET_POST = register("target_post") :: MemoryModuleType<GuardPost.GuardPost>,
	DESIGNATED_POSTS = register("designated_posts") :: MemoryModuleType<{GuardPost.GuardPost}>,
	PATROL_STATE = register("patrol_state") :: MemoryModuleType<"RESUMING" | "UNEMPLOYED" | "WALKING" | "STAYING">,
	POST_VACATE_COOLDOWN = register("post_vacate_cooldown") :: MemoryModuleType<number>,
	IS_CURIOUS = register("is_curious") :: MemoryModuleType<boolean>,
	IS_PANICKING = register("is_panicking") :: MemoryModuleType<boolean>,
	IS_FLEEING = register("is_fleeing") :: MemoryModuleType<boolean>,
	IS_INTIMIDATED = register("is_intimidated") :: MemoryModuleType<boolean>,
	HAS_FLED = register("has_fled") :: MemoryModuleType<true>,
	PANIC_POSITION = register("panic_position") :: MemoryModuleType<Vector3>,
	CONFRONTING_TRESPASSER = register("confronting_trespasser") :: MemoryModuleType<Player>
}

return MemoryModuleTypes