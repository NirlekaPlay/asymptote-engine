--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)
local LightingNames = require(ServerScriptService.server.world.lighting.LightingNames)

local WHITE = Color3.new(1, 1, 1)

local MissionSetupReaderV1 = {}

local function isLegacyConfig(config: { [any]: any }): boolean
	return config.canBeTrespassed ~= nil or config.penalties ~= nil
end

local function upgradeLegacyConfig(
	cellName: string,
	legacy: { [any]: any }
): CellConfig.CellConfig
	warn(`Cell '{cellName}' uses legacy config format. Consider upgrading to the new format.`)

	if not legacy.canBeTrespassed then
		-- cell wasnt trespassing at all in old format
		return {
			trespass = false,
		}
	end

	local allow: { [string]: true } = {}
	local minorTrespass: { [string]: true } = {}

	-- old format: disguised players got a different (usually minor) penalty
	-- we map that to minorTrespass for all disguises since old format
	-- had no per-disguise granularity. use a sentinel key to indicate
	-- "any disguise counts as minor trespass"
	local penalties = legacy.penalties
	if penalties then
		local disguisedPenalty = penalties.disguised
		if disguisedPenalty == "MINOR_TRESPASSING" then
			minorTrespass["*"] = true
		elseif disguisedPenalty == nil then
			allow["*"] = true
		end
		-- if disguisedPenalty == MAJOR_TRESPASSING we do nothing,
		-- falls through to major trespass for everyone
	end

	return {
		trespass = true,
		allow = next(allow) ~= nil and allow or nil,
		minorTrespass = next(minorTrespass) ~= nil and minorTrespass or nil,
		enforce = nil,
		enforceMinor = nil,
	}
end

local function parseCellEntry(
	cellName: string,
	entry: any
): CellConfig.ParsedCellEntry
	if type(entry) == "string" then
		return {
			kind = "expression",
			expression = entry,
		}
	end

	if type(entry) ~= "table" then
		warn(`Cell '{cellName}' has invalid config type '{typeof(entry)}', skipping.`)
		return {
			kind = "config",
			config = { trespass = false }
		}
	end

	if isLegacyConfig(entry) then
		return {
			kind = "config",
			config = upgradeLegacyConfig(cellName, entry)
		}
	end

	local bluffConfig: CellConfig.BluffConfig? = nil
	local bluffField = entry.MinorTrespassBluff
	if bluffField and type(bluffField) == "table" then
		bluffConfig = {
			socialEngineeringLevel = bluffField.SocialEngineeringLevel or 0,
			excuse = bluffField.Excuse or "",
			responseSpeaker = bluffField.ResponseSpeaker or "",
			response = bluffField.Response or "",
			variable = bluffField.Variable or "",
		}
	end

	return {
		kind = "config",
		config = {
			trespass = entry.Trespass == true,
			allow = entry.Allow or nil,
			minorTrespass = entry.MinorTrespass or nil,
			enforce = entry.Enforce or nil,
			enforceMinor = entry.EnforceMinor or nil,
			minorTrespassBluff = bluffConfig,
		}
	}
end

local function parseCellConfigs(
	raw: { [string]: any }
): CellConfig.ParsedCellConfigs
	local parsed: CellConfig.ParsedCellConfigs = {}

	for cellName, entry in raw do
		parsed[cellName] = parseCellEntry(cellName, entry)
	end

	return parsed
end

function MissionSetupReaderV1.parse(missionSetupModule: ModuleScript): MissionSetup.MissionSetup
	local required = (require :: any)(missionSetupModule) :: { [any]: any }

	local localizedStrings = required["CustomStrings"] or {}
	local rawCellConfigs = required["Cells"] or {}
	--[=[
		Security = {
			Name = "name.disguise.security",
			Outfits = {
				{ 4893814518, 4893808612 },
			},
			DisguiseClass = 0,
			BrickColor = BrickColor.idk
		},
	]=]
	local rawDisguiseConfigs = required["CustomDisguises"] or {}
	local enforceClasses = required["EnforceClass"]
	local lightingSettings = required["LightingSettings"]
	local lightingSettingsObj

	local disguiseConfigs = {}

	for disguiseName, rawConfig in rawDisguiseConfigs do
		disguiseConfigs[disguiseName] = {
			nameLocalizedKey = rawConfig.Name,
			upperBodyBrickColor = rawConfig.BrickColor,
			disguiseClass = rawConfig.DisguiseClass,
			outfitIds = rawConfig.Outfits
		}
	end

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
	local dialoguesField = required["Dialogues"]
	local dialoguesPayload = {
		speakers = {},
		concepts = {}
	}
	local starterPackItems = required["StarterPack"] or {}
	local cinematics = required["Cinematics"] or {}

	if dialoguesField then
		local speakersField = dialoguesField["Speakers"]
		if speakersField and next(speakersField) ~= nil then
			for speakerId, configs in speakersField do
				local component = MutableTextComponent.literal(speakerId)
					:withStyle(
						TextStyle.empty()
							:withColor(
								TextColor.fromColor3(configs.TextColor or WHITE)
							)
					):serialize()
				dialoguesPayload.speakers[speakerId] = component
			end
		end

		local conceptsField = dialoguesField["Concepts"]
		if conceptsField and next(conceptsField) ~= nil then
			dialoguesPayload.concepts = conceptsField
		end
	end

	local cellConfigs = parseCellConfigs(rawCellConfigs)

	local newMissionSetup = MissionSetup.new(
		localizedStrings,
		cellConfigs,
		disguiseConfigs,
		enforceClasses,
		lightingSettingsObj,
		colors,
		objectives,
		globals,
		dialoguesPayload,
		starterPackItems,
		cinematics
	)

	return newMissionSetup
end

return MissionSetupReaderV1