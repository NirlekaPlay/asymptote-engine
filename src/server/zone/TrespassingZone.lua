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
end

return TrespassingZone