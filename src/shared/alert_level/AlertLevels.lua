--!strict

export type AlertLevel = {
	name: string
}

local function register(name: string): AlertLevel
	return { name = name }
end

local AlertLevels = {
	CALM = register("calm"),
	NORMAL = register("normal"),
	ALERT = register("alert"),
	SEARCHING = register("searching"),
	LOCKDOWN = register("lockdown")
}

return AlertLevels