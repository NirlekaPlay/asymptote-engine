--!strict

local PlayerStatus = {}
PlayerStatus.__index = PlayerStatus

export type PlayerStatus = typeof(setmetatable({} :: {
	name: string,
	priorityLevel: number,
	requiresVisibility: boolean,
	detectionSpeedModifier: number
}, PlayerStatus))

function PlayerStatus.new(name: string, priority: number, mustSee: boolean, speedModifier: number): PlayerStatus
	return setmetatable({
		name = name,
		priorityLevel = priority,
		requiresVisibility = mustSee,
		detectionSpeedModifier = speedModifier
	}, PlayerStatus)
end

function PlayerStatus.getPriorityLevel(self: PlayerStatus): number
	return self.priorityLevel
end

function PlayerStatus.getDetectionSpeedModifier(self: PlayerStatus): number
	return self.detectionSpeedModifier
end

return PlayerStatus