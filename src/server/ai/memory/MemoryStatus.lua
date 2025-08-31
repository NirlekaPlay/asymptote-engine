--!strict

export type MemoryStatus = {
	name: string
}

local function register(name: string): MemoryStatus
	return { name = name }
end

local MemoryStatuses = {
	REGISTERED = register("REGISTERED"),
	VALUE_PRESENT = register("VALUE_PRESENT"),
	VALUE_ABSENT = register("VALUE_ABSENT")
}

return MemoryStatuses