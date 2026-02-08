--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local CommandContextBuilder = require(ReplicatedStorage.shared.commands.context.CommandContextBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local ParseResults = {}
ParseResults.__index = ParseResults

export type ParseResults<S> = typeof(setmetatable({} :: {
	context: CommandContextBuilder.CommandContextBuilder<S>,
	errors: { [CommandNode.CommandNode<S>]: ErrorResult },
	reader: StringReader.StringReader
}, ParseResults))

export type ErrorResult = { message: string, cursorPos: number }

function ParseResults.new<S>(
	context: CommandContextBuilder.CommandContextBuilder<S>,
	reader: StringReader.StringReader,
	errors: { [CommandNode.CommandNode<S>]: ErrorResult }
): ParseResults<S>
	return setmetatable({
		context = context,
		errors = errors,
		reader = reader
	}, ParseResults)
end

function ParseResults.getContext<S>(self: ParseResults<S>): CommandContextBuilder.CommandContextBuilder<S>
	return self.context
end

function ParseResults.getErrors<S>(self: ParseResults<S>): { [CommandNode.CommandNode<S>]: string }
	return self.errors
end

function ParseResults.getReader<S>(self: ParseResults<S>): StringReader.StringReader
	return self.reader
end

return ParseResults