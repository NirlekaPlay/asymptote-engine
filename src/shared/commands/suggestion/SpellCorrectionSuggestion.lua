--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UString = require(ReplicatedStorage.shared.util.string.UString)

local SpellCorrectonSuggestion = {}

function SpellCorrectonSuggestion.didYouMean(userInputStr: string, strLists: {string}): string?
	local bestMatches: { string } = {}
	local minDistance = math.huge

	for _, cmd in ipairs(strLists) do
		local distance = UString.damerauLevenshteinDistance(userInputStr, cmd)
		if distance < minDistance then
			minDistance = distance
			bestMatches = {cmd}  -- new best match
		elseif distance == minDistance then
			table.insert(bestMatches, cmd)  -- tie
		end
	end

	local suggestStr = "Did you mean "
	local suggestionSize = #bestMatches

	if suggestionSize == 1 then
		suggestStr ..= "'" .. bestMatches[1] .. "'?"
	elseif suggestionSize == 2 then
		suggestStr ..= "'" .. bestMatches[1] .. "' and '" .. bestMatches[2] .. "'?"
	elseif suggestionSize == 0 then
		return nil
	else
		for i = 1, suggestionSize - 1 do
			suggestStr ..= "'" .. bestMatches[i] .. "', "
		end
		suggestStr ..= "and '" .. bestMatches[suggestionSize] .. "'?"
	end

	return suggestStr
end

return SpellCorrectonSuggestion