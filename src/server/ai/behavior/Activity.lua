--!strict

export type Activity = {
	name: string
}

local function register(name: string): Activity
	return {
		name = name,
	}
end

return {
	IDLE = register("idle"),
	CORE = register("core"),
	WORK = register("work"),
	INVESTIGATE = register("investigate"),
	PANIC = register("panic")
}