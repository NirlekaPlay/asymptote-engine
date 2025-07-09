--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedStatusRemote = require(ReplicatedStorage.shared.network.TypedStatusRemote)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)
local Statuses = require(ServerScriptService.server.player.Statuses)
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
	local susLevel = PlayerStatusReg.getSuspiciousLevel(player)
	local isDisguised = susLevel:hasStatus(Statuses.PLAYER_STATUSES.DISGUISED)
	local finalStatus: TrespassingStatusType

	if isDisguised then
		finalStatus = self.config.penalties.disguised
	else
		finalStatus = self.config.penalties.undisguised
	end

	if finalStatus then
		self.playersGivenStatus[player] = finalStatus
		susLevel:setStatus(finalStatus, true)
		TypedStatusRemote:FireClient(player, finalStatus, true)
	end
end

function TrespassingZone.onPlayerLeave(self: TrespassingZone, player: Player): ()
	local susLevel = PlayerStatusReg.getSuspiciousLevel(player)
	local givenStatus = self.playersGivenStatus[player]

	if givenStatus then
		susLevel:setStatus(givenStatus, false)
		TypedStatusRemote:FireClient(player, givenStatus, false)
	end
end

function TrespassingZone.update(self: TrespassingZone): ()
	self.triggerZone:update()
end

return TrespassingZone