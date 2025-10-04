--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local QuoteOfTheDay = require(ReplicatedStorage.shared.quotes.QuoteOfTheDay)
local QuoteOfTheDayList = require(ReplicatedStorage.shared.quotes.QuoteOfTheDayList)

local QuoteOfTheDayCommand = {}

function QuoteOfTheDayCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("quote")
			:andThen(
				LiteralArgumentBuilder.new("list")
					:executes(QuoteOfTheDayCommand.listQuotes)
			)
			:andThen(
				LiteralArgumentBuilder.new("predict")
					:executes(QuoteOfTheDayCommand.nextQuote)
			)
			:andThen(
				LiteralArgumentBuilder.new("schedule")
					:executes(QuoteOfTheDayCommand.listSchedule)
			)
	)
end

function QuoteOfTheDayCommand.listQuotes(context: CommandContext.CommandContext<Player>): number
	local source = context:getSource()
	local allQuotes = QuoteOfTheDayList
	
	local quoteListText = "All quotes:\n"
	for i, quote in ipairs(allQuotes) do
		local formattedQuote = QuoteOfTheDayCommand.formatQuote(quote, i)
		quoteListText = quoteListText .. formattedQuote .. "\n"
	end

	quoteListText = quoteListText:sub(1, -2)

	print(quoteListText)
	
	TypedRemotes.ClientBoundChatMessage:FireClient(source, {
		literalString = quoteListText, 
		type = "plain"
	})

	return 1
end

function QuoteOfTheDayCommand.nextQuote(context: CommandContext.CommandContext<Player>): number
	local nextQuote = QuoteOfTheDay.getNextQuote()
	local formattedQuote = QuoteOfTheDayCommand.formatQuote(nextQuote)
	local nextQuoteHours = QuoteOfTheDay.getHoursUntilNextQuote()
	local formattedHours = QuoteOfTheDayCommand.formatTime(nextQuoteHours)
	local predictionText = `The next quote is:\n{formattedQuote}\n in {formattedHours}`
	local source = context:getSource()

	TypedRemotes.ClientBoundChatMessage:FireClient(source, {
		literalString = predictionText, 
		type = "plain"
	})

	return 1
end

function QuoteOfTheDayCommand.listSchedule(context: CommandContext.CommandContext<Player>): number
	local fullSchedule = QuoteOfTheDay.getFullQuoteSchedule()
	local scheduleText = ""

	for _, entry in ipairs(fullSchedule) do
		local date = `[{tostring(os.date("%Y-%m-%d %H:%M:%S", os.time(entry.date :: any)))}] `
		scheduleText = scheduleText .. date .. QuoteOfTheDayCommand.formatQuote(entry.quote) .. "\n"
	end

	local source = context:getSource()

	TypedRemotes.ClientBoundChatMessage:FireClient(source, {
		literalString = scheduleText, 
		type = "plain"
	})

	return 1
end

function QuoteOfTheDayCommand.formatQuote(quote: QuoteOfTheDayList.Quote, i: number?): string
	if i then
		return "Index: " .. i .. " Quote: " .. quote.message .. ", author: " .. quote.author
	else
		return "Quote: " .. quote.message .. ", author: " .. quote.author
	end
end

function QuoteOfTheDayCommand.formatTime(timeInHours: number): string
	-- Convert fractional hours into total seconds
	local totalSeconds = math.floor(timeInHours * 3600)

	-- Extract days, hours, minutes, seconds
	local days = math.floor(totalSeconds / (24 * 3600))
	local remainingSeconds = totalSeconds % (24 * 3600)

	local hrs = math.floor(remainingSeconds / 3600)
	remainingSeconds = remainingSeconds % 3600

	local mins = math.floor(remainingSeconds / 60)
	local secs = remainingSeconds % 60

	-- Choose the most appropriate unit to display
	if days > 0 then
		return days .. (days == 1 and " day" or " days")
	elseif hrs > 0 then
		return hrs .. (hrs == 1 and " hour" or " hours")
	elseif mins > 0 then
		return mins .. (mins == 1 and " minute" or " minutes")
	else
		return secs .. (secs == 1 and " second" or " seconds")
	end
end

return QuoteOfTheDayCommand