--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)

--[=[
	@class MissionManager
]=]
local MissionManager = {}
MissionManager.__index = MissionManager

export type MissionManager = typeof(setmetatable({} :: {
	missionConcluded: boolean,
	playersWantingRetry: { [Player]: true },
	cameraSocket: CameraSocket.CameraSocket, -- TODO: Bad. VERY BAD. NOOO-,
	serverLevel: ServerLevel.ServerLevel
}, MissionManager))

function MissionManager.new(serverLevel: ServerLevel.ServerLevel): MissionManager
	return setmetatable({
		missionConcluded = false,
		playersWantingRetry = {},
		cameraSocket = nil :: any,
		serverLevel = serverLevel
	}, MissionManager)
end

function MissionManager.setCameraSocket(self: MissionManager, socket: CameraSocket.CameraSocket): ()
	self.cameraSocket = socket
end

function MissionManager.concludeMission(self: MissionManager): ()
	if self.missionConcluded then
		return
	end
	self.missionConcluded = true
	TypedRemotes.ClientBoundMissionConcluded:FireAllClients(self.cameraSocket)
end

function MissionManager.isConcluded(self: MissionManager): boolean
	return self.missionConcluded
end

function MissionManager.onLevelRestart(self: MissionManager): ()
	self.missionConcluded = false
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

return MissionManager