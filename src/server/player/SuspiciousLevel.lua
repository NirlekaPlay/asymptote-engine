--!strict

local Statuses = require("./Statuses")

local SuspiciousLevel = {}
SuspiciousLevel.__index = SuspiciousLevel

export type SuspiciousLevel = typeof(setmetatable({} :: {
	statuses: { [PlayerStatus]: true },
	_weight: number,
	_weightNeedUpdate: boolean
}, SuspiciousLevel))

type PlayerStatus = Statuses.PlayerStatus

function SuspiciousLevel.new(): SuspiciousLevel
	return setmetatable({
		statuses = {},
		_weight = 0,
		_weightNeedUpdate = false
	}, SuspiciousLevel)
end

function SuspiciousLevel.getTotalWeight(self: SuspiciousLevel): number
	if self._weightNeedUpdate then
		local totalWeight = 0
		for status, _ in pairs(self.statuses) do
			local weight = Statuses.STATUS_BY_WEIGHT[status]
			totalWeight += weight
		end

		return totalWeight
	else
		return self._weight
	end
end

function SuspiciousLevel.getHighestPriorityStatus(self: SuspiciousLevel): Statuses.PlayerStatus
	local maxPriority = 1
end

function SuspiciousLevel.getStatuses(self: SuspiciousLevel): { [PlayerStatus]: true }
	return table.clone(self.statuses)
end

function SuspiciousLevel.hasStatus(self: SuspiciousLevel, status: PlayerStatus): boolean
	return self.statuses[status] ~= nil
end

function SuspiciousLevel.isSuspicious(self: SuspiciousLevel): boolean
	return next(self.statuses) ~= nil
end

function SuspiciousLevel.setStatus(self: SuspiciousLevel, status: PlayerStatus, bool: boolean): ()
	if bool then
		self.statuses[status] = true
	else
		self.statuses[status] = nil
	end
	self._weightNeedUpdate = true
end

return SuspiciousLevel