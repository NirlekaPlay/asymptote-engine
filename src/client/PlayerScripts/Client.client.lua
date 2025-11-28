--!strict

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local IndicatorsRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.renderer.hud.indicator.IndicatorsRenderer)
local LocalPlayer = Players.LocalPlayer

-- Localization:

TypedRemotes.ClientBoundLocalizationAppend.OnClientEvent:Connect(function(dict)
	ClientLanguage.appendFromDict(dict)
end)

local success, translator = pcall(function()
	return LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer)
end)

local userLocaleId
if success and translator then
	userLocaleId = translator.LocaleId
	print("LOCALE")
else
	userLocaleId = "en-us"
	print("FALLBACK")
end

print("The user's current locale is: " .. userLocaleId)

ClientLanguage.load()

-- So that languages can be loaded properly before anything uses it
local Objectives = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.objectives.Objectives)

RunService.PreRender:Connect(function(deltaTime)
	IndicatorsRenderer.update()
end)
