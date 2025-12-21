--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local LightingNames = require(ServerScriptService.server.world.lighting.LightingNames)

local MissionSetupReaderV1 = {}

function MissionSetupReaderV1.parse(missionSetupModule: ModuleScript): MissionSetup.MissionSetup
	local required = (require :: any)(missionSetupModule) :: { [any]: any }
	local localizedStrings = required["CustomStrings"] or {}
	local cellsConfigs = required["Cells"] or {}
	local disguiseConfigs = required["CustomDisguises"] or {}
	local enforceClasses = required["EnforceClass"]
	local lightingSettings = required["LightingSettings"]
	local lightingSettingsObj
	if lightingSettings then
		local fetch = (LightingNames :: any)[lightingSettings]
		if not fetch then
			warn(`'{lightingSettings}' is not a valid Lighting preset name`)
		end

		lightingSettingsObj = fetch
	end
	local colors = required["Colors"] or {}
	local objectives = required["Objectives"] or {}
	local globals = required["Globals"] or {}

	local newMissionSetup = MissionSetup.new(
		localizedStrings,
		cellsConfigs,
		disguiseConfigs,
		enforceClasses,
		lightingSettingsObj,
		colors,
		objectives,
		globals
	)

	return newMissionSetup
end

return MissionSetupReaderV1