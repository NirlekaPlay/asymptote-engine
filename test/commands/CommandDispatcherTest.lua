--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

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

return CommandDispatcherTest