--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local TypedStatusRemote = require(ReplicatedStorage.shared.network.TypedRemotes).Status

--[=[
	@class PlayerStatusHolder
]=]
local PlayerStatusHolder = {}
PlayerStatusHolder.__index = PlayerStatusHolder

export type PlayerStatusHolder = typeof(setmetatable({} :: {
	player: Player,
	currentStatusesMap: { [PlayerStatus]: true }
}, PlayerStatusHolder))

type PlayerStatus = PlayerStatus.PlayerStatus

function PlayerStatusHolder.new(player: Player): PlayerStatusHolder
	return setmetatable({
		player = player,
		currentStatusesMap = {}
	}, PlayerStatusHolder)
end

function PlayerStatusHolder.addStatus(self: PlayerStatusHolder, statusType: PlayerStatus): ()
	self.currentStatusesMap[statusType] = true
	self:syncStatusesToClient()
end

function PlayerStatusHolder.clearAllStatuses(self: PlayerStatusHolder): ()
	for statusType in pairs(self.currentStatusesMap) do
		self.currentStatusesMap[statusType] = nil
	end
	self:syncStatusesToClient()
end

function PlayerStatusHolder.removeStatus(self: PlayerStatusHolder, statusType: PlayerStatus): ()
	self.currentStatusesMap[statusType] = nil
	self:syncStatusesToClient()
end

function PlayerStatusHolder.hasStatus(self: PlayerStatusHolder, statusType: PlayerStatus): boolean
	return self.currentStatusesMap[statusType] ~= nil
end

function PlayerStatusHolder.hasAnyStatus(self: PlayerStatusHolder): boolean
	return next(self.currentStatusesMap) ~= nil
end

function PlayerStatusHolder.getHighestPriorityStatus(self: PlayerStatusHolder): PlayerStatus?
	local highestStatus: PlayerStatus? = nil
	local highestPriority: number = -math.huge

	for playerStatus in pairs(self.currentStatusesMap) do
		local priority = playerStatus:getPriorityLevel()
		if priority > highestPriority then
			highestPriority = priority
			highestStatus = playerStatus
		end
	end

	return highestStatus
end

function PlayerStatusHolder.getHighestDetectableStatus(self: PlayerStatusHolder, isVisible: boolean, isHeard: boolean): PlayerStatus?
	local currentStatuses: { PlayerStatus } = {}
	for status in pairs(self.currentStatusesMap) do
		table.insert(currentStatuses, status)
	end

	table.sort(currentStatuses, function(a, b)
		return a:getPriorityLevel() > b:getPriorityLevel()
	end)

	for _, status in ipairs(currentStatuses) do
		if isVisible or (not status.requiresVisibility and isHeard) then
			return status
		end
	end

	return nil
end

function PlayerStatusHolder.syncStatusesToClient(self: PlayerStatusHolder): ()
	-- sigh. serialization bullshit.
	local serializedMap: { [string]: true } = {}
	for playerStatus in pairs(self.currentStatusesMap) do
		serializedMap[playerStatus.name] = true
	end
	TypedStatusRemote:FireClient(self.player, serializedMap)
end

return PlayerStatusHolder