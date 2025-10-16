--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UString = require(ReplicatedStorage.shared.suggestion.UString)

local UStringTests = {}

function UStringTests.testDemerauLevenshteinDistances()
	print(UString.damerauLevenshteinDistance("wow", "wow"))
	print(UString.damerauLevenshteinDistance("abc", "acb"))
	print(UString.damerauLevenshteinDistance("student", "studnet"))
end

function UStringTests.testUstringExplode()
	local str = "月が綺麗ですね。"
	local exploded = UString.explodeString(str)
	print(exploded)
end

function UStringTests.testDidYouMean()
	-- 1. Single best match
	local single = UStringTests.didYouMean("studnt", {"student", "stunt"})
	print(single)

	-- 2. Two best matches (tie)
	local two = UStringTests.didYouMean("strat", {"strategy", "stratu", "status"})
	print(two)

	-- 3. More than two best matches (tie)
	local many = UStringTests.didYouMean("sta", {"status", "statu", "stark", "stamina"})
	print(many)

	-- 4. Empty list (no suggestions)
	local empty = UStringTests.didYouMean("anything", {})
	print(empty)
end

function UStringTests.didYouMean(userInputStr: string, strLists: { string })
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
		return "No suggestions."
	else
		for i = 1, suggestionSize - 1 do
			suggestStr ..= "'" .. bestMatches[i] .. "', "
		end
		suggestStr ..= "and '" .. bestMatches[suggestionSize] .. "'?"
	end

	return suggestStr
end

return UStringTests