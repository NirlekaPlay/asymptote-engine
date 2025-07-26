--!strict

local Behavior = {}
Behavior.__index = Behavior

Behavior.Status = {
	RUNNING = "RUNNING" :: "RUNNING",
	STOPPED = "STOPPED" :: "STOPPED"
}

export type Status = "RUNNING"
	| "STOPPED"

return Behavior