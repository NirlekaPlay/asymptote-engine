--!strict

--[=[
	@class PlayerStatus
]=]
local PlayerStatus = {}
PlayerStatus.__index = PlayerStatus

export type PlayerStatus = typeof(setmetatable({} :: {
	currentStatusesMap: { [PlayerStatusType]: true }
}, PlayerStatus))

export type PlayerStatusType = "DISGUISED"
	| "MINOR_TRESPASSING"
	| "MINOR_SUSPICIOUS"
	| "MAJOR_TRESPASSING"
	| "CRIMINAL_SUSPICIOUS"
	| "ARMED"

local PLAYER_STATUSES_BY_PRIORITY = {
	"DISGUISED",
	"MINOR_TRESPASSING",
	"MINOR_SUSPICIOUS",
	"MAJOR_TRESPASSING",
	"CRIMINAL_SUSPICIOUS",
	"ARMED"
}

local PLAYER_STATUSES_BY_DETECTION_SPEED_MODIFIER = {
	DISGUISED = -37.5,
	MINOR_TRESPASSING = 0,
	MINOR_SUSPICIOUS = 0,
	MAJOR_TRESPASSING = 25,
	CRIMINAL_SUSPICIOUS = 25,
	ARMED = 50
}

function PlayerStatus.new(): PlayerStatus
	return setmetatable({
		currentStatusesMap = {}
	}, PlayerStatus)
end

function PlayerStatus.addStatus(self: PlayerStatus, statusType: PlayerStatusType): ()
	self.currentStatusesMap[statusType] = true
end

function PlayerStatus.removeStatus(self: PlayerStatus, statusType: PlayerStatusType): ()
	self.currentStatusesMap[statusType] = nil
end

function PlayerStatus.hasStatus(self: PlayerStatus, statusType: PlayerStatusType): boolean
	return self.currentStatusesMap[statusType] ~= nil
end

function PlayerStatus.hasAnyStatus(self: PlayerStatus): boolean
	return next(self.currentStatusesMap) ~= nil
end

function PlayerStatus.getHighestPriorityStatus(self: PlayerStatus): (PlayerStatusType?, number?)
	for i = #PLAYER_STATUSES_BY_PRIORITY, 1, -1 do
		local status = PLAYER_STATUSES_BY_PRIORITY[i]
		if self.currentStatusesMap[status] then
			return status, i
		end
	end
	return nil, nil
end

function PlayerStatus.getStatusDetectionSpeedModifier(statusType: PlayerStatusType): number
	return PLAYER_STATUSES_BY_DETECTION_SPEED_MODIFIER[statusType]
end

return PlayerStatus