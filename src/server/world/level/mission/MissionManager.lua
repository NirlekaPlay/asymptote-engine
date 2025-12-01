--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

--[=[
	@class MissionManager
]=]
local MissionManager = {}
MissionManager.__index = MissionManager

export type MissionManager = typeof(setmetatable({} :: {
	missionConcluded: boolean
}, MissionManager))

function MissionManager.new(): MissionManager
	return setmetatable({
		missionConcluded = false
	}, MissionManager)
end

function MissionManager.concludeMission(self: MissionManager): ()
	if self.missionConcluded then
		return
	end
	self.missionConcluded = true
	TypedRemotes.ClientBoundMissionConcluded:FireAllClients()
end

function MissionManager.isConcluded(self: MissionManager): boolean
	return self.missionConcluded
end

function MissionManager.onLevelRestart(self: MissionManager): ()
	
end

return MissionManager