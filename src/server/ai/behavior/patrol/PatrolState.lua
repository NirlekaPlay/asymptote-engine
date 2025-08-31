--!strict

export type PatrolState = {
	name: string
}

local function register(name: string): PatrolState
	return { name = name }
end

local PatrolStates = {
	RESUMING = register("resuming"),
	WALKING = register("walking"),
	STAYING = register("staying"),
	UNEMPLOYED = register("unemployed")
}

return PatrolStates