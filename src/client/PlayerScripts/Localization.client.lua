
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local LocalPlayer = Players.LocalPlayer

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