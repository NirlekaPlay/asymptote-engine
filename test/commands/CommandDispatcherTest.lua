--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local SharedSuggestionProvider = require(ReplicatedStorage.shared.commands.asymptote.suggestion.SharedSuggestionProvider)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local StringRange = require(ReplicatedStorage.shared.commands.context.StringRange)

local CommandDispatcherTest = {}
CommandDispatcherTest.__index = CommandDispatcherTest

export type CommandDispatcherTest = typeof(setmetatable({} :: {
	dispatcher: CommandDispatcher.CommandDispatcher<any>,
	command: CommandFunction.CommandFunction<any>,
	source: any,
}, CommandDispatcherTest))

local literal = LiteralArgumentBuilder.literal
local argument = RequiredArgumentBuilder.argument

function CommandDispatcherTest.setUp()
	local self = setmetatable({}, CommandDispatcherTest)

	self.dispatcher = CommandDispatcher.new() :: CommandDispatcher.CommandDispatcher<any>
	self.command = function<S>(c: CommandContext.CommandContext<S>)
		print("Command executed successfully! Context:", c)
		return 1
	end
	self.source = {} :: any

	return self
end

--

function CommandDispatcherTest.testDispatcherType(self: CommandDispatcherTest)
	self.dispatcher:register(
		literal("foo")
			:executes(self.command)
	)

	assert(self.dispatcher:execute("foo", self.source))
end

--

function CommandDispatcherTest.getCompletionSuggestions_redirect(self: CommandDispatcherTest)
	local actual = self.dispatcher:register(
		literal("actual")
			:andThen(
				literal("sub")
					:executes(self.command)
			)
	)

	self.dispatcher:register(
		literal("redirect")
			:redirect(actual)
	)

	local parse = self.dispatcher:parseString("redirect ", self.source)
	local result = self.dispatcher:getCompletionSuggestions(parse, self.source):join()

	local expectedRange = StringRange.at(9)
	assert(result:getRange():equals(expectedRange), "Range mismatch")

	local list = result:getList()
	assert(#list == 1, "Should have 1 suggestion")
	assert(list[1]:getText() == "sub", "Suggestion text mismatch")
	assert(list[1]:getRange():equals(expectedRange), "Suggestion range mismatch")
end

function CommandDispatcherTest.getCompletionSuggestions_argument(self: CommandDispatcherTest)
	self.dispatcher:register(
		literal("foo")
			:andThen(
				argument("bar", BooleanArgumentType.bool())
					:executes(self.command)
			)
	)

	local parse = self.dispatcher:parseString("foo ", self.source)
	local result = self.dispatcher:getCompletionSuggestions(parse, self.source):join()

	local range = result:getRange()
	assert(range:getStart() == 4, "Overall range start should be 4")
	assert(range:getEnd() == 4, "Overall range end should be 4")

	local suggestions = result:getList()
	assert(#suggestions == 2, "Should have exactly 2 suggestions (true/false)")

	local suggestion1 = suggestions[1]
	assert(suggestion1:getText() == "false", "First suggestion should be 'false'")
	assert(suggestion1:getRange():getStart() == 4, "Suggestion 1 range start mismatch")

	local suggestion2 = suggestions[2]
	assert(suggestion2:getText() == "true", "Second suggestion should be 'true'")
	assert(suggestion2:getRange():getStart() == 4, "Suggestion 2 range start mismatch")
end

return CommandDispatcherTest