
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local LocalPlayer = Players.LocalPlayer

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