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

--[=[
	@class CommandDispatcher

	The core command CommandDispatcher, for registering, parsing, and executing commands.
]=]
local CommandDispatcher = {}
CommandDispatcher.__index = CommandDispatcher

local ARGUMENT_SEPARATOR = " "

local ARGUMENT_SEPARATOR_CHAR = ' '

local USAGE_OPTIONAL_OPEN = "["
local USAGE_OPTIONAL_CLOSE = "]"
local USAGE_REQUIRED_OPEN = "("
local USAGE_REQUIRED_CLOSE = ")"
local USAGE_OR = "|"

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

--[=[
	Utility method to register new commands.
]=]
function CommandDispatcher.register<S>(self: CommandDispatcher<S>, command: LiteralArgumentBuilder<S>): CommandNode<S>
	local node = command:build()
	self.root:addChild(node)
	return node
end

--[=[
	Sets a callback to be informed of the result of every command.
]=]
function CommandDispatcher.setConsumer<S>(self: CommandDispatcher<S>, consumer: ResultConsumer<S>): ()
	self.consumer = consumer
end

--[=[
	Gets the dispatcher's command root.
]=]
function CommandDispatcher.getRoot<S>(self: CommandDispatcher<S>): CommandNode<S>
	return self.root
end

function CommandDispatcher.getAllUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: any, restricted: boolean): {string}
	local result: {string} = {}
	self:_getAllUsage(node, source, result, "", restricted)
	return result
end

function CommandDispatcher._getAllUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: S, result: {string}, prefix: string, restricted: boolean)
	-- TODO: This is a very bad design for a method.
	-- Should just return a value and not mutate the result table.
	if restricted and not node:canUse(source) then
		return
	end
	
	if node.command then
		table.insert(result, prefix)
	end
	
	if node.redirect then
		local redirect = node:getRedirect() == self.root and "..." or "-> " .. node.redirect:getUsageText()
		local redirectText = prefix == "" and node:getUsageText() .. " " .. redirect or prefix .. " " .. redirect
		table.insert(result, redirectText)
	elseif node.children then
		for _, child in node.children do
			local newPrefix = prefix == "" and child:getUsageText() or prefix .. " " .. child:getUsageText()
			self:_getAllUsage(child, source, result, newPrefix, restricted)
		end
	end
end

function CommandDispatcher.getSmartUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: S): { [CommandNode<S>]: string }
	local result: { [CommandNode<S>]: string } = {}
	local optional = node:getCommand() ~= nil

	for _, child in pairs(node:getChildren()) do
		local usage = self:_getSmartUsage(child, source, optional, false)
		if usage ~= nil then
			result[child] = usage
		end
	end

	return result;
end

function CommandDispatcher._getSmartUsage<S>(self: CommandDispatcher<S>, node: CommandNode<S>, source: S, optional: boolean, deep: boolean): string?
	if not node:canUse(source) then
		return nil
	end

	local selfStr = optional and USAGE_OPTIONAL_OPEN .. node:getUsageText() .. USAGE_OPTIONAL_CLOSE or node:getUsageText()
	local childOptional = node:getCommand() ~= nil
	local open = childOptional and USAGE_OPTIONAL_OPEN or USAGE_REQUIRED_OPEN
	local close = childOptional and USAGE_OPTIONAL_CLOSE or USAGE_REQUIRED_CLOSE

	if not deep then
		if node:getRedirect() ~= nil then
			local redirect = node:getRedirect() == self.root and "..." or "-> " .. node:getRedirect():getUsageText()
			return selfStr .. ARGUMENT_SEPARATOR .. redirect
		else
			local children: { CommandNode<S> } = {}
			local childrenCount = 0
			local firstChild: CommandNode<S>?
			for _, child in pairs(node:getChildren()) do
				if child:canUse(source) then
					childrenCount += 1
					if not firstChild then
						firstChild = child
					end
					table.insert(children, child)
				end
			end

			if childrenCount == 1 and firstChild then
				local usage = self:_getSmartUsage(firstChild, source, childOptional, childOptional)
				if usage ~= nil then
					return selfStr .. ARGUMENT_SEPARATOR .. usage
				end
			elseif childrenCount > 1 then
				local childUsage: { [string]: true } = {}
				local childUsageCount = 0
				local firstUsage: string?
				for _, child in pairs(children) do
					local usage = self:_getSmartUsage(child, source, childOptional, true)
					if usage ~= nil then
						childUsageCount += 1
						if not firstUsage then
							firstUsage = usage
						end
						childUsage[usage] = true
					end
				end

				if childUsageCount == 1 and firstChild then
					local usage = firstUsage
					return selfStr .. ARGUMENT_SEPARATOR .. (childOptional and USAGE_OPTIONAL_OPEN .. usage .. USAGE_OPTIONAL_CLOSE or usage)
				elseif childUsageCount > 1 and firstChild then
					local str = open
					local count = 0
					for _, child in pairs(children) do
						if count > 0 then
							str ..= USAGE_OR
						end
						str ..= child:getUsageText()
						count += 1
					end

					if count > 0 then
						str ..= close
						return selfStr .. ARGUMENT_SEPARATOR .. str
					end
				end
			end
		end
	end

	return selfStr
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
	if parse:getReader():canRead() then
		local errors = parse:getErrors()
		local errorsCount = 0
		local firstError = nil

		for _, err in pairs(errors) do
			errorsCount += 1
			if not firstError then
				firstError = err
			end
		end

		if errorsCount == 1 then
			error(firstError)
		elseif parse:getContext():getRange():isEmpty() then
			error("UNKNOWN_COMMAND")
		else
			error("UNKNOWN_ARGUMENT")
		end
	end

	local result = 0
	local successfulForks = 0
	local forked = false
	local foundCommand = false
	local command = parse:getReader():getString()
	local original = parse:getContext():build(command)
	local contexts: { CommandContext<S> }? = {original}
	local next: {CommandContext<S>}? = nil

	while contexts ~= nil do
		for _, context in contexts do
			local child = context:getChild()
			

			if child ~= nil then
				forked = forked or (nil) -- child:isForked()

				if child:hasNodes() then
					foundCommand = true
					local modifier = nil -- context:getRedirectModifier()
					if modifier == nil then
						if next == nil then
							next = {}
						end
						table.insert((next :: any), child:copyFor(context:getSource()))
					else
						-- TODO: redirection stuff here
					end
				end
			elseif context:getCommand() ~= nil then
				foundCommand = true

				local success, err = pcall(function()
					local value = context:getCommand()(context)
					result += value
					self.consumer.onCommandComplete(context, true, value)
					successfulForks += 1
				end)

				if not success then
					self.consumer.onCommandComplete(context, false, result)
					if not forked then
						error(err)
					end
				end
			end
		end

		contexts = next
		next = nil
	end

	if not foundCommand then
		self.consumer.onCommandComplete(original, false, result)
		error("UNKNOWN_COMMAND")
	end

	return forked and successfulForks or result
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

		context:withCommand(childNode:getCommand())
		if reader:canRead(childNode:getRedirect() == nil and 2 or 1) then
			reader:skip()

			if childNode:getRedirect() ~= nil then
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
	if #potentials > 0 then
		if #potentials > 1 then
			table.sort(potentials, function(a: ParseResults<S>, b: ParseResults<S>)
				if not a:getReader():canRead() and b:getReader():canRead() then
					return true
				end
				if a:getReader():canRead() and not b:getReader():canRead() then
					return false
				end
				if next(a:getErrors()) == nil and next(b:getErrors()) ~= nil then
					return true
				end
				if next(a:getErrors()) ~= nil and next(b:getErrors()) == nil then
					return false
				end
				return false
			end)
		end

		return potentials[1] -- return the parse result from the deepest branch
	end

	return ParseResults.new(contextSoFar, originalReader, errors)
end

return CommandDispatcher