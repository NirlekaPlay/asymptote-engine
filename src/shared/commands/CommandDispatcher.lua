--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local ResultConsumer = require(ReplicatedStorage.shared.commands.ResultConsumer)
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandContextBuilder = require(ReplicatedStorage.shared.commands.context.CommandContextBuilder)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

local EMPTY_RESULT_CONSUMER: ResultConsumer<any> = {
	onCommandComplete = function(context: CommandContext<any>, success: boolean, result: number)
		return
	end
}

local ARGUMENT_SEPARATOR_CHAR = ' '

--[=[
	@class CommandDispatcher

	The core command CommandDispatcher, for registering, parsing, and executing commands.
]=]
local CommandDispatcher = {}
CommandDispatcher.__index = CommandDispatcher

export type CommandDispatcher<S> = typeof(setmetatable({} :: {
	root: CommandNode<S>,
	consumer: ResultConsumer<S>
}, CommandDispatcher))

type CommandNode<S> = CommandNode.CommandNode<S>
type CommandContext<S> = CommandContext.CommandContext<S>
type LiteralArgumentBuilder<S> = LiteralArgumentBuilder.LiteralArgumentBuilder<S>
type ParseResults<S> = ParseResults.ParseResults<S>
type ResultConsumer<S> = ResultConsumer.ResultConsumer<S>

--[=[
	Creates a new `CommandDispatcher` with an empty command tree.
]=]
function CommandDispatcher.new<S>(): CommandDispatcher<S>
	return setmetatable({
		root = CommandNode.new("", "literal", nil) :: CommandNode<S>,
		consumer = EMPTY_RESULT_CONSUMER :: ResultConsumer<S>
	}, CommandDispatcher)
end

function CommandDispatcher.register<S>(self: CommandDispatcher<S>, command: LiteralArgumentBuilder<S>): CommandNode<S>
	local node = command:build()
	self.root:addChild(node)
	return node
end

function CommandDispatcher.setConsumer<S>(self: CommandDispatcher<S>, consumer: ResultConsumer<S>): ()
	self.consumer = consumer
end

function CommandDispatcher.getRoot<S>(self: CommandDispatcher<S>): CommandNode<S>
	return self.root
end

function CommandDispatcher.getAllUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: any, restricted: boolean): {string}
	local result: {string} = {}
	self:_getAllUsage(node, source, result, "", restricted)
	return result
end

function CommandDispatcher._getAllUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: S, result: {string}, prefix: string, restricted: boolean)
	if restricted and not node:canUse(source) then
		return
	end
	
	if node.command then
		table.insert(result, prefix)
	end
	
	if node.redirect then
		local redirect = node.redirect == self.root and "..." or "-> " .. node.redirect:getUsageText()
		local redirectText = prefix == "" and node:getUsageText() .. " " .. redirect or prefix .. " " .. redirect
		table.insert(result, redirectText)
	elseif node.children then
		for _, child in node.children do
			local newPrefix = prefix == "" and child:getUsageText() or prefix .. " " .. child:getUsageText()
			self:_getAllUsage(child, source, result, newPrefix, restricted)
		end
	end
end

--

function CommandDispatcher.execute<S>(self: CommandDispatcher<S>, input: string, source: S): number
	local parseResults = self:parseString(input, source)
	return self:executeParsed(parseResults, source)
end

function CommandDispatcher.executeParsed<S>(
	self: CommandDispatcher<S>, 
	parse: ParseResults.ParseResults<S>
): number
	local context = parse:getContext()
	local node = (context :: any).currentNode
	-- At this point, validation already happened in finishParsing
	-- So we can assume we have a valid command to execute
	
	if not node or node.command == nil then
		error("No executable command found") -- This shouldn't happen after validation
	end
	
	-- Execute the command
	local success, result = pcall(function()
		return node.command(context)
	end)
	
	if success then
		-- Notify consumer of success
		self.consumer.onCommandComplete(context, true, result or 0)
		return result or 0
	else
		-- Notify consumer of failure
		self.consumer.onCommandComplete(context, false, 0)
		error(result) -- Re-throw the error
	end
end

function CommandDispatcher.parseString<S>(self: CommandDispatcher<S>, inputStr: string, source: S): ParseResults.ParseResults<S>
	return self:parse(StringReader.fromString(inputStr), source)
end

function CommandDispatcher.parse<S>(self: CommandDispatcher<S>, input: StringReader.StringReader, source: S): ParseResults.ParseResults<S>
	return self:parseNodes(self.root, input, CommandContextBuilder.new(source, self.root, input:getCursorPos()))
end

function CommandDispatcher.parseNodes<S>(
	self: CommandDispatcher<S>,
	node: CommandNode<S>,
	originalReader: StringReader.StringReader,
	contextSoFar: CommandContextBuilder.CommandContextBuilder<S>
): ParseResults.ParseResults<S>

	local source = contextSoFar:getSource()
	local errors: { [CommandNode<S>]: string } = {}
	local potentials: { ParseResults<S> } = {}
	local cursorPos = originalReader:getCursorPos()

	for _, childNode in pairs(node:getRelevantNodes(originalReader)) do
		if not childNode:canUse(source) then
			continue
		end

		local context = contextSoFar:copy()
		local reader = StringReader.fromOther(originalReader)

		local success, err = pcall(function()
			childNode:parse(reader, context)
			if reader:canRead() then
				if reader:peek() ~= ARGUMENT_SEPARATOR_CHAR then
					error("EXPECTED_ARGUMENT_SEPERATOR") -- replace it with an actual error message.
				end
			end
		end)

		if not success then
			-- Errors returned by `pcall` and other methods always includes the traceback.
			-- e.g. "ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser:218: Player 's' not found"
			-- This prevents that.
			errors[childNode] = ((err :: any) :: string):match("^[^:]+:%d+: (.+)") -- what the fuck.
			reader:setCursorPos(cursorPos)
			continue
		end

		context:withCommand(childNode.command) -- there should be a fucking method for this.
		if reader:canRead(if childNode.redirect then 2 else 1) then -- again.. A METHOD!!!
			reader:skip()

			if childNode.redirect ~= nil then
				local childContext = CommandContextBuilder.new(source, childNode.redirect, reader:getCursorPos())
				local parse = self:parseNodes(childNode.redirect, reader, childContext) -- istg recursion feels like a sin.
				context:withChild(childContext)
				return ParseResults.new(context, parse:getReader(), parse:getErrors())
			else
				local parse = self:parseNodes(childNode, reader, context)
				table.insert(potentials, parse)
			end
		else
			table.insert(potentials, ParseResults.new(context, reader, {}))
		end
	end

	-- oh so this is why we should leave it as nil...
	-- so when we check, we just gotta check if its nil instead of using the
	-- `#` operator which recounts it...
	-- ill fix it later.

	-- for some fucking reason the function signature on this cannot correctly resolve the types of a and b.
	if #potentials > 1 then
		(table.sort :: any)(potentials, function(a: ParseResults<S>, b: ParseResults<S>)
			-- Prefer results where reader is fully consumed (can't read more)
			if not a:getReader():canRead() and b:getReader():canRead() then
				return true  -- a comes first
			end
			if a:getReader():canRead() and not b:getReader():canRead() then
				return false  -- b comes first
			end
			-- Prefer results with no errors
			if (next(a:getErrors()) == nil) and not (next(b:getErrors()) == nil) then
				return true  -- a comes first
			end
			if not (next(a:getErrors()) == nil) and (next(b:getErrors()) == nil) then
				return true  -- a comes first (this was also wrong - you had -1 again)
			end
			return false  -- equal, maintain order
		end)
		return potentials[1]
	end

	return ParseResults.new(contextSoFar, originalReader, errors)
end

return CommandDispatcher