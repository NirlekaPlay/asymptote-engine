--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedStatusRemote = require(ReplicatedStorage.shared.network.TypedStatusRemote)

--[=[
	@class PlayerStatus
]=]
local PlayerStatus = {}
PlayerStatus.__index = PlayerStatus

export type PlayerStatus = typeof(setmetatable({} :: {
	player: Player,
	currentStatusesMap: { [PlayerStatusType]: true }
}, PlayerStatus))

export type PlayerStatusType = "DISGUISED"
	| "MINOR_TRESPASSING"
	| "MINOR_SUSPICIOUS"
	| "MAJOR_TRESPASSING"
	| "CRIMINAL_SUSPICIOUS"
	| "DANGEROUS_ITEM"
	| "ARMED"

local PLAYER_STATUS_PRIORITY_ORDER: { PlayerStatusType } = {
	"DISGUISED",
	"MINOR_TRESPASSING",
	"MINOR_SUSPICIOUS",
	"MAJOR_TRESPASSING",
	"CRIMINAL_SUSPICIOUS",
	"DANGEROUS_ITEM",
	"ARMED"
}

local PLAYER_STATUSES_BY_DETECTION_SPEED_MODIFIER = {
	DISGUISED = -37.5,
	MINOR_TRESPASSING = 0,
	MINOR_SUSPICIOUS = 0,
	MAJOR_TRESPASSING = 25,
	CRIMINAL_SUSPICIOUS = 25,
	DANGEROUS_ITEM = 50,
	ARMED = 50
}

function PlayerStatus.new(player: Player): PlayerStatus
	return setmetatable({
		player = player,
		currentStatusesMap = {}
	}, PlayerStatus)
end

function PlayerStatus.addStatus(self: PlayerStatus, statusType: PlayerStatusType): ()
	self.currentStatusesMap[statusType] = true
	self:syncStatusesToClient()
end

function PlayerStatus.clearAllStatuses(self: PlayerStatus): ()
	for statusType in pairs(self.currentStatusesMap) do
		self.currentStatusesMap[statusType] = nil
	end
	self:syncStatusesToClient()
end

function PlayerStatus.removeStatus(self: PlayerStatus, statusType: PlayerStatusType): ()
	self.currentStatusesMap[statusType] = nil
	self:syncStatusesToClient()
end

function PlayerStatus.hasStatus(self: PlayerStatus, statusType: PlayerStatusType): boolean
	return self.currentStatusesMap[statusType] ~= nil
end

function PlayerStatus.hasAnyStatus(self: PlayerStatus): boolean
	return next(self.currentStatusesMap) ~= nil
end

function PlayerStatus.getHighestPriorityStatus(self: PlayerStatus): PlayerStatusType?
	for i = #PLAYER_STATUS_PRIORITY_ORDER, 1, -1 do
		local status = PLAYER_STATUS_PRIORITY_ORDER[i]
		if self.currentStatusesMap[status] then
			return status
		end
	end
	return nil
end

function PlayerStatus.syncStatusesToClient(self: PlayerStatus): ()
	TypedStatusRemote:FireClient(self.player, self.currentStatusesMap)
end

function PlayerStatus.getStatusPriorityValue(statusType: PlayerStatusType): number
	for i, status in ipairs(PLAYER_STATUS_PRIORITY_ORDER) do
		if status == statusType then
			return i
		end
	end
	return 0
end

function PlayerStatus.getStatusDetectionSpeedModifier(statusType: PlayerStatusType): number
	return PLAYER_STATUSES_BY_DETECTION_SPEED_MODIFIER[statusType]
end

return PlayerStatus