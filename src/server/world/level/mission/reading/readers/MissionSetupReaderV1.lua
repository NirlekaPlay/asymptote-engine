--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local LightingNames = require(ServerScriptService.server.world.lighting.LightingNames)

local WHITE = Color3.new(1, 1, 1)

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
	local dialoguesField = required["Dialogues"]
	local dialoguesPayload = {
		speakers =  {},
		concepts = {}
	}
	local starterPackItems = required["StarterPack"] or {}

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

	local newMissionSetup = MissionSetup.new(
		localizedStrings,
		cellsConfigs,
		disguiseConfigs,
		enforceClasses,
		lightingSettingsObj,
		colors,
		objectives,
		globals,
		dialoguesPayload,
		starterPackItems
	)

	return newMissionSetup
end

return MissionSetupReaderV1