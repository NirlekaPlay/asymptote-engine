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
function QuoteOfTheDay.getQuoteOfTheDay(dayOffset: number?, halfDayOffset: number?): QuoteOfTheDaysList.Quote
	return QuoteOfTheDay.getQuoteOfTheDayWithDate(os.date("!*t"), dayOffset, halfDayOffset)
end

--[=[
	Returns the next Quote after this day.
]=]
function QuoteOfTheDay.getNextQuote(): QuoteOfTheDaysList.Quote
	return QuoteOfTheDay.getQuoteOfTheDay(0, 1)
end

--[=[
	Returns a Quote with a custom `Date` object.
]=]
function QuoteOfTheDay.getQuoteOfTheDayWithDate(date: typeof(os.date()), dayOffset: number?, halfDayOffset: number?): QuoteOfTheDaysList.Quote
	local dayOfYear = date.yday      -- 1 to 366
	local hour = date.hour           -- 0 to 23
	local year = date.year
	local halfDay = math.floor(hour / 12)
	if dayOffset then
		dayOfYear += dayOffset
	end
	if halfDayOffset then
		halfDay += halfDayOffset
	end

	-- Create a more complex deterministic seed using bitwise operations
	-- Shift year left by 5, XOR with dayOfYear shifted left by 3, XOR with halfDay
	local seed = bit32.bxor(bit32.lshift(year, 5), bit32.lshift(dayOfYear, 3), halfDay)

	-- Shuffle the quotes using the new seed
	local shuffledQuotes = seededShuffle(QuoteOfTheDaysList, seed)

	-- Select index deterministically
	local index = ((dayOfYear - 1) % #shuffledQuotes) + 1
	local selectedQuote = shuffledQuotes[index]

	return selectedQuote
end

--[=[
	Get hours until next quote.
]=]
function QuoteOfTheDay.getHoursUntilNextQuote(): number
	local date = os.date("!*t")
	local hour = date.hour    -- 0 to 23
	local min = date.min      -- 0 to 59
	local sec = date.sec      -- 0 to 59

	-- Determine which 12-hour period we are in
	local halfDay = math.floor(hour / 12)

	-- Calculate the start of the next half-day
	local nextHalfDayStart = (halfDay + 1) * 12

	-- Hours until next half-day
	local hoursRemaining = nextHalfDayStart - hour - 1
	local minutesRemaining = 59 - min
	local secondsRemaining = 60 - sec

	-- Convert remaining minutes and seconds to fractional hours
	local totalHoursRemaining = hoursRemaining + (minutesRemaining / 60) + (secondsRemaining / 3600)
	return totalHoursRemaining
end

--[=[
	Generates a list of all quotes along with their corresponding day and half-day.
]=]
function QuoteOfTheDay.getFullQuoteSchedule(startDate: typeof(os.date("!*t"))?)
	startDate = startDate or os.date("!*t")

	local totalQuotes = #QuoteOfTheDaysList
	local schedule = {}

	-- Keep track of seen quotes to ensure all quotes are shown
	local seenQuotes = {}
	local dayOffset = 0
	local halfDayOffset = 0

	while #schedule < totalQuotes do
		local quote = QuoteOfTheDay.getQuoteOfTheDayWithDate(startDate, dayOffset, halfDayOffset)

		-- Only add if not already in the schedule
		if not seenQuotes[quote] then
			-- Compute the date for this quote
			local quoteDate = os.date("!*t", os.time({
				year = startDate.year,
				month = startDate.month,
				day = startDate.day + dayOffset,
				hour = halfDayOffset * 12,
				min = 0,
				sec = 0
			}))

			table.insert(schedule, {
				quote = quote,
				date = quoteDate
			})
			seenQuotes[quote] = true
		end

		-- Move to the next half-day
		halfDayOffset += 1
		if halfDayOffset >= 2 then
			halfDayOffset = 0
			dayOffset += 1
		end
	end

	return schedule
end

--[=[
	Returns the quote, if it exist, assosciated with the index
	from the QuoteOfTheDayList.
]=]
function QuoteOfTheDay.getQuoteOfTheDayByIndex(index: number): QuoteOfTheDaysList.Quote?
	return QuoteOfTheDaysList[index]
end

return QuoteOfTheDay