--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DisguiseConfig = require(ServerScriptService.server.disguise.DisguiseConfig)
local EnforceClass = require(ServerScriptService.server.disguise.EnforceClass)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)

local UNLOCALIZED_STRING = "UNLOCALIZED_STRING"

--[=[
	@class MissionSetup
]=]
local MissionSetup = {}
MissionSetup.__index = MissionSetup

export type MissionSetup = typeof(setmetatable({} :: {
	localizedStrings: { [string]: string },
	cells: { [string]: CellConfig.Config },
	disguiseConfigs: { [string]: DisguiseConfig.DisguiseConfig },
	enforceClasses: { [string]: EnforceClass.EnforceClass },
	lightingSettings: LightingSettings?,
	colors: { [string]: Color3 },
	objectives: any -- TODO: FOR NOW
}, MissionSetup))

type LightingSettings = { [any]: any }

function MissionSetup.new(
	localizedStrings: { [string]: string },
	cells: { [string]: CellConfig.Config },
	disguiseConfigs: { [string]: DisguiseConfig.DisguiseConfig },
	enforceClasses: { [string]: EnforceClass.EnforceClass },
	lightingSettings: LightingSettings?,
	colors: { [string]: Color3 },
	objectives: any
): MissionSetup
	return setmetatable({
		localizedStrings = localizedStrings,
		cells = cells,
		disguiseConfigs = disguiseConfigs,
		enforceClasses = enforceClasses,
		lightingSettings = lightingSettings,
		colors = colors,
		objectives = objectives
	}, MissionSetup)
end

function MissionSetup.getLocalizedString(self: MissionSetup, keyStr: string): string
	return self.localizedStrings[keyStr] or UNLOCALIZED_STRING
end

function MissionSetup.getCellConfig(self: MissionSetup, cellName: string): CellConfig.Config
	local cellConfig = self.cells[cellName]
	if not cellConfig then
		error(`Attempt to fetch a non-existent cell config of name '{cellName}'`)
	end

	return cellConfig
end

function MissionSetup.getDisguiseConfig(self: MissionSetup, disguiseName: string): DisguiseConfig.DisguiseConfig
	local disguiseConfig = self.disguiseConfigs[disguiseName]
	if not disguiseConfig then
		error(`Attempt to fetch a non-existent disguise config of name '{disguiseName}'`)
	end

	return disguiseConfig
end

function MissionSetup.getEnforceClass(self: MissionSetup, profileName: string): EnforceClass.EnforceClass
	local enforceClass = self.enforceClasses[profileName]
	if not enforceClass then
		error(`Attempt to fetch a non-existent enforce class profile of name '{profileName}'`)
	end

	return enforceClass
end

function MissionSetup.hasLightingSettings(self: MissionSetup): boolean
	return self.lightingSettings ~= nil
end

function MissionSetup.getLightingSettings(self: MissionSetup): LightingSettings
	if self.lightingSettings == nil then
		error(`Attempt to fetch unset LightingSettings`)
	else
		return self.lightingSettings
	end
end

function MissionSetup.getColor(self: MissionSetup, colorName: string): Color3
	local color = self.colors[colorName]
	if not color then
		error(`Attempt to fetch non-existent color '{colorName}'`)
	end

	return color
end

function MissionSetup.getObjectives(self: MissionSetup): any
	return self.objectives
end

return MissionSetup