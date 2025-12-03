--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local TriggerZone = require(ServerScriptService.server.world.level.clutter.props.triggers.TriggerZone)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)

local MISSION_FAILED_VARIABLE = "Mission_Failed"

GlobalStatesHolder.setState(MISSION_FAILED_VARIABLE, false)

--[=[
	@class MissionManager
]=]
local MissionManager = {}
MissionManager.__index = MissionManager

export type MissionManager = typeof(setmetatable({} :: {
	missionConcluded: boolean,
	playersWantingRetry: { [Player]: true },
	cameraSocket: CameraSocket.CameraSocket, -- TODO: Bad. VERY BAD. NOOO-,
	serverLevel: ServerLevel.ServerLevel,
	missionFailedConnection: RBXScriptConnection
}, MissionManager))

function MissionManager.new(serverLevel: ServerLevel.ServerLevel): MissionManager
	local self =  setmetatable({
		missionConcluded = false,
		playersWantingRetry = {},
		cameraSocket = nil :: any,
		serverLevel = serverLevel
	}, MissionManager)

	self.missionFailedConnection = GlobalStatesHolder.getStateChangedConnection(MISSION_FAILED_VARIABLE):Connect(function(v)
		if v then
			self:failMission()
		end
	end)

	return self
end

function MissionManager.setCameraSocket(self: MissionManager, socket: CameraSocket.CameraSocket): ()
	self.cameraSocket = socket
end

function MissionManager.failMission(self: MissionManager): ()
	GlobalStatesHolder.setState(MISSION_FAILED_VARIABLE, true)
	self:concludeMission()
end

function MissionManager.concludeMission(self: MissionManager): ()
	if self.missionConcluded then
		return
	end
	self.missionConcluded = true
	TypedRemotes.ClientBoundMissionConcluded:FireAllClients(self.cameraSocket, GlobalStatesHolder.getState(MISSION_FAILED_VARIABLE))
end

function MissionManager.isConcluded(self: MissionManager): boolean
	return self.missionConcluded
end

function MissionManager.onLevelRestart(self: MissionManager): ()
	self.missionConcluded = false
	GlobalStatesHolder.setState(MISSION_FAILED_VARIABLE, false)
end

function MissionManager.canRestart(self: MissionManager): boolean
	if self.serverLevel:isRestarting() then
		return false
	end

	local playersInGame = #Players:GetPlayers()
	
	local playersWantingRetryCount = 0
	for _, wantsRetry in pairs(self.playersWantingRetry) do
		if wantsRetry then
			playersWantingRetryCount += 1
		end
	end
	
	return playersWantingRetryCount >= playersInGame
end

function MissionManager.onPlayerWantRetry(self: MissionManager, player: Player): ()
	if not self:isConcluded() then
		return
	end

	self.playersWantingRetry[player] = true
	
	if self:canRestart() then
		table.clear(self.playersWantingRetry)
		self.serverLevel:restartLevel()
	end
end

function MissionManager.onPlayerLeaving(self: MissionManager, player: Player): ()
	if not self:isConcluded() then
		return
	end

	self.playersWantingRetry[player] = nil
	
	if self:canRestart() then
		self.serverLevel:restartLevel()
	end
end

function MissionManager.onPlayerDied(self: MissionManager, player: Player): ()
	local validPlayers = MissionManager.getValidPlayersSet()
	local count = 0
	for player in validPlayers do
		count += 1
	end

	if count <= 0 then
		self:failMission()
	end
end

function MissionManager.getValidPlayersSet(): { [Player]: true }
	local set: { [Player]: true } = {}
	for _, player in Players:GetPlayers() do
		if MissionManager.isValidPlayer(player) then
			set[player] = true
		end
	end
	return set
end

function MissionManager.isValidPlayer(player: Player): boolean
	local pos = TriggerZone.getPlayerPos(player)
	if not pos then
		return false
	end

	local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true
end

return MissionManager