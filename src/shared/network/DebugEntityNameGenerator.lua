--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)

--[=[
	@class DebugEntityNameGenerator

	Based on Minecraft's name generator for debugging
	purposes, this class generates a deterministic but
	random name based on an Entity or Agent's UUID.
]=]
local DebugEntityNameGenerator = {}

--[=[
	Co-authored by @htment!
]=]
local NAMES_FIRST_PART = {
	"Delta",
	"Splendid",
	"Soft",
	"Rotund",
	"Silly",
	"Shy",
	"Average",
	"Mumbo",
	"Red",
	"Cold",
	"Wet",
	"French",
	"Hard",
	"Black",
	"High",
	"Flat",
	"Sad",
	"Blue",
	"Zenless",
	"Keeth",
	"Bald",
	"Depressed",
	"Deez",
	"Captain",
	"Wobbling", -- @htment
	"Sir",
	"Crusty",
	"General",
	"Glistening",
	"Doctor",
	"Slightly",
	"Professor",
	"Suspicious",
	"Reverend",
	"Screaming",
	"Baron",
	"Soggy",
	"Admiral",
	"Goopy",
	"Sergeant",
	"Weeping",
	"Agent",
	"Chancellor",
	"Corporal",
	"Bubbling",
	"Fluffy",
	"The",
	"Mister"
}

local NAMES_SECOND_PART = {
	"Specimen",
	"Lad",
	"Cobalt",
	"Joe",
	"Jumbo",
	"Commie",
	"Bread",
	"Tissue",
	"Cuirassier",
	"Billy",
	"Fox",
	"Jeans",
	"Potato",
	"Box",
	"Birdie",
	"Imposter",
	"Pea",
	"Crystal",
	"Beepo",
	"Nuts",
	"Puddle", -- @htment
	"Muffin",
	"Beans",
	"Toaster",
	"Pants",
	"Armpit",
	"Waffle",
	"Ferret",
	"Gristle",
	"Doorknob",
	"Nugget",
	"Toe",
	"Pickle",
	"Sock",
	"Doodle",
	"Fiasco",
	"McStuffins",
	"Lampshade",
	"Spatula",
	"Kerfuffle",
	"Tater-Tot",
	"Gravy",
	"Shinbone",
	"Sneeze",
	"Phlegm"
}

--[=[
	If Agent already has a character name, simply returns that.
	Returns a generated name based on the Agent's UUID if
	Agent:GetCharacterName() returns nil or an empty string.
]=]
function DebugEntityNameGenerator.getEntityName(agent: Agent.Agent): string
	local charName = agent:getCharacterName()
	if charName and charName ~= "" then
		return charName
	else
		local seed = DebugEntityNameGenerator.getSeedFromUuid(agent:getUuid())
		local random = Random.new(seed)
		local prefix = DebugEntityNameGenerator.getRandomString(random, NAMES_FIRST_PART)
		local suffix = DebugEntityNameGenerator.getRandomString(random, NAMES_SECOND_PART)
		return prefix .. suffix
	end
end

function DebugEntityNameGenerator.hashUuid(uuid: string): number
	local hash = 0
	for i = 1, #uuid do
		local c = string.byte(uuid, i)
		hash = (hash * 31 + c) % 2^32
	end
	return hash
end

function DebugEntityNameGenerator.getSeedFromUuid(uuid: string): number
	local hash = DebugEntityNameGenerator.hashUuid(uuid)
	return bit32.rshift(hash, 2)
end

function DebugEntityNameGenerator.getRandomString(random: Random, list: {string}): string
	return list[random:NextInteger(1, #list)]
end

return DebugEntityNameGenerator