--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local AlertLevels = require(ReplicatedStorage.shared.alertlevel.AlertLevels)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local ALERT_LEVELS = {
	[0] = AlertLevels.CALM,
	[1] = AlertLevels.NORMAL,
	[2] = AlertLevels.ALERT,
	[3] = AlertLevels.SEARCHING,
	[4] = AlertLevels.LOCKDOWN
}

local MAX_ALERT_LEVEL = 4

local Mission = {
	missionAlertLevel = 0
}

local GLOBAL_STATE_STR = "Mission_AlertLevel"
local ALARM_RAISED_STATRE_STR = "Mission_AlarmRaised"
GlobalStatesHolder.setState(GLOBAL_STATE_STR, 0)
GlobalStatesHolder.setState(ALARM_RAISED_STATRE_STR, false)

function Mission.getAlertLevel(): AlertLevels.AlertLevel
	local discreteLevel = math.floor(Mission.missionAlertLevel)
	discreteLevel = math.clamp(discreteLevel, 0, MAX_ALERT_LEVEL)
	return ALERT_LEVELS[discreteLevel]
end

function Mission.getAlertLevelNumericValue(alertLevel: AlertLevels.AlertLevel)
	for value, level in pairs(ALERT_LEVELS) do
		if level == alertLevel then
			return value
		end
	end
	return 0
end

function Mission.raiseAlertLevel(amount: number): ()
	Mission.missionAlertLevel = math.clamp(Mission.missionAlertLevel + amount, 0, MAX_ALERT_LEVEL)
	Mission.syncAlertLevelToClients()
	GlobalStatesHolder.setState(GLOBAL_STATE_STR, Mission.missionAlertLevel)
	if Mission.missionAlertLevel >= 3 then
		GlobalStatesHolder.setState(ALARM_RAISED_STATRE_STR, true)
	end
end

function Mission.syncAlertLevelToClients(): ()
	TypedRemotes.AlertLevel:FireAllClients(Mission.getAlertLevel())
end

function Mission.resetAlertLevel(): ()
	Mission.missionAlertLevel = 0
	Mission.syncAlertLevelToClients()
	GlobalStatesHolder.setState(GLOBAL_STATE_STR, 0)
	GlobalStatesHolder.setState(ALARM_RAISED_STATRE_STR, false)
end

return Mission