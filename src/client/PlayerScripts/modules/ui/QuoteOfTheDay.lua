--!strict

local QuoteOfTheDaysList = require("./QuoteOfTheDayList")

--[=[
	@class QuoteOfTheDay

	Gives you a quote of the day from a list,
	which are random for each day.

	Failure to contribute to the Quote of The Day list
	will result in a discplinary action by the Cat herself.
]=]
local QuoteOfTheDay = {}

--[=[
	Deterministic shuffle using a seeded Random.
]=]
local function seededShuffle(list: { any }, seed: number)
	local random = Random.new(seed)
	local shuffled = table.clone(list)
	for i = #shuffled, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

--[=[
	Returns a Quote unique to each day.
]=]
function QuoteOfTheDay.getQuoteOfTheDay(): QuoteOfTheDaysList.Quote
	local date = os.date("!*t")
	local dayOfYear = (os.date("!*t", os.time(date :: any)) :: any).yday -- 1 to 366
	local year = date.year

	-- use the year as the seed (so the list resets each year)
	local shuffledQuotes = seededShuffle(QuoteOfTheDaysList, year)
	local index = ((dayOfYear - 1) % #shuffledQuotes) + 1
	local selectedQuote = shuffledQuotes[index]

	return selectedQuote
end

return QuoteOfTheDay