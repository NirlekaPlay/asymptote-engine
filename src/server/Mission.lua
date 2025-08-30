--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlertLevels = require(ReplicatedStorage.shared.alert_level.AlertLevels)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)

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

function Mission.getAlertLevel(): AlertLevels.AlertLevel
	local discreteLevel = math.floor(Mission.missionAlertLevel)
	discreteLevel = math.clamp(discreteLevel, 0, MAX_ALERT_LEVEL)
	return ALERT_LEVELS[discreteLevel]
end

function Mission.raiseAlertLevel(amount: number): ()
	Mission.missionAlertLevel = math.clamp(Mission.missionAlertLevel + amount, 0, MAX_ALERT_LEVEL)
	Mission.syncAlertLevelToClients()
end

function Mission.syncAlertLevelToClients(): ()
	TypedRemotes.AlertLevel:FireAllClients(Mission.getAlertLevel())
end

return Mission