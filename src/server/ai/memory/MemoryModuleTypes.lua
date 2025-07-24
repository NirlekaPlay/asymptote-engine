--!strict

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
	LOOK_TARGET = register("look_target") :: MemoryModuleType<Player>
}

return MemoryModuleTypes