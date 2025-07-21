--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local TriggerZone = require("./TriggerZone")

--[=[
	@class TrespassingZone
]=]
local TrespassingZone = {}
TrespassingZone.__index = TrespassingZone

export type TrespassingZone = typeof(setmetatable({} :: {
	triggerZone: TriggerZone,
	config: ZoneConfig,
	playersGivenStatus: { [Player]: TrespassingStatusType }
}, TrespassingZone))

export type ZoneConfig = {
	penalties: {
		undisguised: TrespassingStatusType,
		disguised: TrespassingStatusType
	}
}

type TriggerZone = TriggerZone.TriggerZone
type TrespassingStatusType = "MINOR_TRESPASSING" | "MAJOR_TRESPASSING"

function TrespassingZone.new(triggerZone: TriggerZone, config: ZoneConfig): TrespassingZone
	local self = {
		triggerZone = triggerZone,
		config = config,
		playersGivenStatus = {}
	}
	setmetatable(self, TrespassingZone)

	self.triggerZone.onPlayerEnterCallback = function(player: Player)
		self:onPlayerEnter(player)
	end

	self.triggerZone.onPlayerLeaveCallback = function(player: Player)
		self:onPlayerLeave(player)
	end

	self.triggerZone.predicateCallback = function(player: Player)
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return false
		end

		if humanoid.Health <= 0 then
			return false
		end

		return true
	end

	return self
end

function TrespassingZone.fromPart(part: BasePart, config: ZoneConfig): TrespassingZone
	local triggerZone = TriggerZone.fromPart(part)
	return TrespassingZone.new(triggerZone, config)
end

function TrespassingZone.onPlayerEnter(self: TrespassingZone, player: Player): ()
	local susLevel = PlayerStatusRegistry.getPlayerStatuses(player)
	local isDisguised = susLevel:hasStatus("DISGUISED")
	local finalStatus: TrespassingStatusType

	if isDisguised then
		finalStatus = self.config.penalties.disguised
	else
		finalStatus = self.config.penalties.undisguised
	end

	if finalStatus then
		self.playersGivenStatus[player] = finalStatus
		susLevel:addStatus(finalStatus)
	end
end

function TrespassingZone.onPlayerLeave(self: TrespassingZone, player: Player): ()
	local susLevel = PlayerStatusRegistry.getPlayerStatuses(player)
	local givenStatus = self.playersGivenStatus[player]

	if givenStatus and susLevel then
		susLevel:removeStatus(givenStatus)
	end
end

function TrespassingZone.update(self: TrespassingZone): ()
	self.triggerZone:update()

	for player in pairs(self.triggerZone.playersInZone) do
		-- in cases where the player wears a disguise while still in a trespassing zone
		local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
		local isDisguised = playerStatus:hasStatus("DISGUISED")

		local expectedStatus: TrespassingStatusType?
		local currentStatus = self.playersGivenStatus[player]
		if isDisguised then
			expectedStatus = self.config.penalties.disguised
		else
			expectedStatus = self.config.penalties.undisguised
		end

		if expectedStatus ~= currentStatus then
			if currentStatus then
				playerStatus:removeStatus(currentStatus)
				self.playersGivenStatus[player] = nil
			end

			if expectedStatus then
				playerStatus:addStatus(expectedStatus)
				self.playersGivenStatus[player] = expectedStatus
			end
		end
	end
end

return TrespassingZone