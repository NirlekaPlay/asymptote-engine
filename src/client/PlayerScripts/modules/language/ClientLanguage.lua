--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local en_us = require(ReplicatedStorage.shared.assets.lang["en-us"])

local TEMP_STUFF_TO_LOAD: {{[string]: string}} = { en_us :: any }
local UNLOCALIZED_STRING = "UNLOCALIZED_STRING"
local DEBUG_LOCALIZATION_KEYS = false

local storage: { [string]: string } = {}

local ClientLanguage = {}

function ClientLanguage.load(): ()
	for _, dict in TEMP_STUFF_TO_LOAD do
		if DEBUG_LOCALIZATION_KEYS then
			print("Localization: Loading key", dict)
		end
		ClientLanguage.appendFromDict(dict)
	end
end

function ClientLanguage.appendFromDict(dict: { [string]: string }): ()
	for key, str in dict do
		storage[key] = str
	end
end

function ClientLanguage.getOrDefault(key: string, default: string?): string
	local str = storage[key] :: string?
	if str == nil then
		return default or UNLOCALIZED_STRING
	else
		return str
	end
end

function ClientLanguage.parseString(str: string): string
	local parsed = string.gsub(str, "%S+", function(key)
		if ClientLanguage.has(key) then
			return ClientLanguage.getOrDefault(key, key)
		end

		return key
	end)
	
	return parsed
end

function ClientLanguage.has(key: string): boolean
	return storage[key] ~= nil
end

return ClientLanguage