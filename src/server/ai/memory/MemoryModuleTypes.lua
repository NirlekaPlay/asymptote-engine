--!strict

--[=[
	@class MemoryModuleTypes

	For typechecking purposes.
]=]
export type MemoryModuleType<T> = {
	name: string
}

local function createModuleType<T>(name: string): MemoryModuleType<T>
	return {
		name = name,
	}
end

local MemoryModuleTypes = {
	VISIBLE_PLAYERS = createModuleType("VISIBLE_PLAYERS") :: MemoryModuleType< { [Player]: true } >,
	HEARABLE_PLAYERS = createModuleType("HEARABLE_PLAYERS") :: MemoryModuleType< { [Player]: true } >
}

return MemoryModuleTypes