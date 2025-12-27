--!strict

--[=[
	@class DetectableSound

	Static definitions on the types of detectable sounds.
	Which defines their pathfinding cost, its type, and distance ranges
	for wether they're alarming or suspicious.
	Such as gun shots, suppressed gun shots, screams for help, etc.
]=]
local DetectableSound = {}

DetectableSound.Type = {
	ALARMING = 0,
	SUSPICIOUS = 1
}

export type DetectableSound = {
	name: string,
	suspiciousRange: number,
	alarmingRange: number,
	pathfindingCost: number
}

local function register(
	name: string,
	suspiciousRange: number,
	alarmingRange: number,
	pathfindingCost: number
): DetectableSound
	return {
		name = name,
		suspiciousRange = suspiciousRange,
		alarmingRange = alarmingRange,
		pathfindingCost = pathfindingCost
	}
end

DetectableSound.Profiles = {
	GUN_SHOT_UNSUPPRESSED = register("gun_shot_unsuppressed", 970, 920, 970),
	GUN_SHOT_SUPPRESSED = register("gun_shot_suppressed", 80, 45, 80)
}

return DetectableSound