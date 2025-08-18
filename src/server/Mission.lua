--!strict

local ALERT_LEVELS = {
	[0] = "CALM",
	[1] = "NORMAL",
	[2] = "ALERT",
	[3] = "SEARCHING",
	[4] = "LOCKDOWN"
}

local MAX_ALERT_LEVEL = 4

local Mission = {
	missionAlertLevel = 0
}

function Mission.raiseAlertLevel(amount: number): ()
	Mission.missionAlertLevel = math.clamp(Mission.missionAlertLevel + amount, 0, MAX_ALERT_LEVEL)
end

return Mission