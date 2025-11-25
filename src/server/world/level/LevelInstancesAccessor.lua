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
	cellModels: { Model }
}, LevelInstancesAccessor))

function LevelInstancesAccessor.new(
	missionSetup: MissionSetup.MissionSetup,
	cellModels: { Model }
): LevelInstancesAccessor
	return setmetatable({
		missionSetup = missionSetup,
		cellModels = cellModels
	}, LevelInstancesAccessor)
end

function LevelInstancesAccessor.getMissionSetup(self: LevelInstancesAccessor): MissionSetup.MissionSetup
	return self.missionSetup
end

function LevelInstancesAccessor.getCellModels(self: LevelInstancesAccessor): { Model }
	return self.cellModels
end

return LevelInstancesAccessor
