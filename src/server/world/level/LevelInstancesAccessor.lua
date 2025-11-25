--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)

--[=[
	@class LevelInstancesAccessor
]=]
local LevelInstancesAccessor = {}
LevelInstancesAccessor.__index = LevelInstancesAccessor

export type LevelInstancesAccessor = typeof(setmetatable({} :: {
	missionSetup: MissionSetup.MissionSetup,
	cellModels: { Model },
	nodesFolder: Folder?
}, LevelInstancesAccessor))

function LevelInstancesAccessor.new(
	missionSetup: MissionSetup.MissionSetup,
	cellModels: { Model },
	nodesFolder: Folder?
): LevelInstancesAccessor
	return setmetatable({
		missionSetup = missionSetup,
		cellModels = cellModels,
		nodesFolder = nodesFolder
	}, LevelInstancesAccessor)
end

function LevelInstancesAccessor.getMissionSetup(self: LevelInstancesAccessor): MissionSetup.MissionSetup
	return self.missionSetup
end

function LevelInstancesAccessor.getCellModels(self: LevelInstancesAccessor): { Model }
	return self.cellModels
end

function LevelInstancesAccessor.getNodesFolder(self: LevelInstancesAccessor): Folder?
	return self.nodesFolder
end

return LevelInstancesAccessor
