--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)
local QuoteOfTheDay = require(ReplicatedStorage.shared.quotes.QuoteOfTheDay)
local QuoteOfTheDayList = require(ReplicatedStorage.shared.quotes.QuoteOfTheDayList)

local QuoteOfTheDayCommand = {}

function QuoteOfTheDayCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("quote")
			:andThen(
				CommandHelper.literal("list")
					:executes(QuoteOfTheDayCommand.listQuotes)
			)
			:andThen(
				CommandHelper.literal("predict")
					:executes(QuoteOfTheDayCommand.nextQuote)
			)
			:andThen(
				CommandHelper.literal("schedule")
					:executes(QuoteOfTheDayCommand.listSchedule)
			)
	)
end

function QuoteOfTheDayCommand.listQuotes(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local source = context:getSource()
	local allQuotes = QuoteOfTheDayList
	
	local quoteListText = MutableTextComponent.literal("All quotes:\n")
	for i, quote in ipairs(allQuotes) do
		local formattedQuote = QuoteOfTheDayCommand.formatQuote(quote, i)
		quoteListText:appendComponent(formattedQuote)
			:appendString("\n")
	end

	print(quoteListText)
	
	source:sendSuccess(quoteListText)

	return 1
end

function QuoteOfTheDayCommand.nextQuote(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local nextQuote = QuoteOfTheDay.getNextQuote()
	local formattedQuote = QuoteOfTheDayCommand.formatQuote(nextQuote)
	local nextQuoteHours = QuoteOfTheDay.getHoursUntilNextQuote()
	local formattedHours = QuoteOfTheDayCommand.formatTime(nextQuoteHours)
	local predictionText = MutableTextComponent.literal("The next quote is:\n")
		:appendComponent(formattedQuote)
		:appendString("\n")
		:appendComponent(
			MutableTextComponent.literal("in ")
				:appendString(formattedHours)
		)
	local source = context:getSource()

	source:sendSuccess(predictionText)

	return 1
end

function QuoteOfTheDayCommand.listSchedule(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local fullSchedule = QuoteOfTheDay.getFullQuoteSchedule()
	local scheduleText = MutableTextComponent.literal("")

	for i, entry in ipairs(fullSchedule) do
		scheduleText:appendComponent(QuoteOfTheDayCommand.formatDate(entry.date))
			:appendComponent(
				QuoteOfTheDayCommand.formatQuote(entry.quote, i)
					:appendString("\n")
			)
	end

	context:getSource():sendSuccess(scheduleText)

	return 1
end

function QuoteOfTheDayCommand.formatQuote(quote: QuoteOfTheDayList.Quote, i: number?): MutableTextComponent.MutableTextComponent
	local rootText = MutableTextComponent.literal("")
		:appendComponent(
			MutableTextComponent.literal(quote.message .. " ")
				:withStyle(
					TextStyle.empty()
						:withBold(true)
						:withColor(NamedTextColors.CREAM)
				)
		)
		:appendComponent(
			MutableTextComponent.literal(quote.author)
				:withStyle(
					TextStyle.empty()
						:withItalic(true)
						:withColor(NamedTextColors.DARK_AQUA)
				)
		)

	if i then
		return MutableTextComponent.literal("Index: ")
			:withStyle(
				TextStyle.empty()
					:withBold(true)
					:withColor(NamedTextColors.YELLOW)
			)
			:appendComponent(rootText)
	else
		return rootText
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

function QuoteOfTheDayCommand.formatDate(date): MutableTextComponent.MutableTextComponent
	local hyphenText = MutableTextComponent.literal("-")
		:withStyle(
			TextStyle.empty()
				:withColor(NamedTextColors.MUTED_LIGHT_BLUE)
		)
	local dateText = MutableTextComponent.literal("[")
		:appendComponent(
			MutableTextComponent.literal(tostring(date.day))
				:withStyle(
					TextStyle.empty()
						:withColor(NamedTextColors.MUTED_SOFT_AQUA)
				)
		)
		:appendComponent(hyphenText)
		:appendComponent(
			MutableTextComponent.literal(tostring(date.day))
				:withStyle(
					TextStyle.empty()
						:withColor(NamedTextColors.SOFT_YELLOW)
				)
		)
		:appendComponent(hyphenText)
		:appendComponent(
			MutableTextComponent.literal(tostring(date.year))
				:withStyle(
					TextStyle.empty()
						:withColor(NamedTextColors.LIGHT_GRAY)
				)
		)
		:appendString("] ")

	return dateText
end

return QuoteOfTheDayCommand