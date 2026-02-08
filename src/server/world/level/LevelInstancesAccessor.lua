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
	nodesFolder: Folder?,
	geometriesFolder: Folder
}, LevelInstancesAccessor))

function LevelInstancesAccessor.new(
	missionSetup: MissionSetup.MissionSetup,
	cellModels: { Model },
	nodesFolder: Folder?,
	geometriesFolder: Folder
): LevelInstancesAccessor
	return setmetatable({
		missionSetup = missionSetup,
		cellModels = cellModels,
		nodesFolder = nodesFolder,
		geometriesFolder = geometriesFolder
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

function LevelInstancesAccessor.getGeometriesFolder(self: LevelInstancesAccessor): Folder
	return self.geometriesFolder
end

--

function LevelInstancesAccessor.destroy(self: LevelInstancesAccessor): ()
	if self.geometriesFolder then
		self.geometriesFolder:Destroy()
	end

	if self.nodesFolder then
		self.nodesFolder:Destroy()
	end

	self.geometriesFolder = nil :: any
	self.nodesFolder = nil :: any
	self.cellModels = {}
	self.missionSetup = nil :: any
end

return LevelInstancesAccessor
