--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local ResultConsumer = require(ReplicatedStorage.shared.commands.ResultConsumer)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
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
	local node = command:build() :: CommandNode<S> -- cant stfu
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
	local parseResults = self:parse(input, source)
	return self:executeParsed(parseResults, source)
end

function CommandDispatcher.executeParsed<S>(
	self: CommandDispatcher<S>, 
	parse: ParseResults.ParseResults<S>
): number
	local context = parse:getContext()
	local node = (context :: any).currentNode
	print(getmetatable(context))
	
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

function CommandDispatcher.parse<S>(self: CommandDispatcher<S>, input: string, source: S): ParseResults.ParseResults<S>
	return self:parseNodes(self.root, input, source, {})
end

function CommandDispatcher.parseNodes<S>(
	self: CommandDispatcher<S>,
	node: CommandNode<S>,
	remaining: string,
	source: S,
	argsSoFar: {[string]: any}
): ParseResults.ParseResults<S>
	remaining = remaining:gsub("^%s+", "")
	local errors: { [CommandNode.CommandNode<S>]: string } = {}
	
	if remaining == "" then
		-- End of input - return this parse if node can execute
		if node:canExecute() then
			local ctx = CommandContext.new(argsSoFar, source);
			(ctx :: any).currentNode = node
			return ParseResults.new(ctx, {}, "")
		end
		-- Return a parse result with errors indicating we couldn't complete
		local ctx = CommandContext.new(argsSoFar, source);
		(ctx :: any).currentNode = node
		return ParseResults.new(ctx, {[node] = "Node cannot execute"}, remaining)
	end
	
	local potentials: {ParseResults.ParseResults<S>} = {}
	local nextWord = remaining:match("^%S+") :: string
	
	-- Try literal children
	local literalChild = node:getChild(nextWord)
	if literalChild and literalChild.nodeType == "literal" then
		local newRemaining = remaining:sub(#nextWord + 1):gsub("^%s+", "")
		local targetNode = literalChild.redirect or literalChild
		local result = self:parseNodes(targetNode, newRemaining, source, argsSoFar)
		table.insert(potentials, result)
	end
	
	-- Try ALL argument children
	for _, child in node.children do
		if child.nodeType == "argument" and child.argumentType then
			local success, value, consumed: number = pcall(child.argumentType.parse, child.argumentType, remaining)
			if success then
				local newArgs = table.clone(argsSoFar)
				newArgs[child.name] = value
				local newRemaining = remaining:sub(consumed + 1):gsub("^%s+", "")
				local targetNode = child.redirect or child
				
				-- Recursively parse rest
				local result = self:parseNodes(targetNode, newRemaining, source, newArgs)
				table.insert(potentials, result)
			else
				-- Errors returned by `pcall` and other methods always includes the traceback.
				-- e.g. "ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser:218: Player 's' not found"
				-- This prevents that.
				errors[child] = ((value :: any) :: string):match("^[^:]+:%d+: (.+)") -- what the fuck.
			end
		end
	end
	
	-- If we have potential parses, return the best one
	if #potentials > 0 then
		-- Sort by: 1) least remaining, 2) fewest errors
		table.sort(potentials, function(a: ParseResults.ParseResults<S>, b: ParseResults.ParseResults<S>)
			local aRemaining = #a:getRemaining()
			local bRemaining = #b:getRemaining()
			
			-- Prefer the one that consumed more input (less remaining)
			if aRemaining ~= bRemaining then
				return aRemaining < bRemaining
			end
			
			-- If same remaining, prefer the one with fewer errors
			local aErrorCount = 0
			for _ in pairs(a:getErrors()) do aErrorCount = aErrorCount + 1 end
			local bErrorCount = 0
			for _ in pairs(b:getErrors()) do bErrorCount = bErrorCount + 1 end
			
			return aErrorCount < bErrorCount
		end)
		
		return potentials[1]
	end
	
	-- No valid children, but if current node can execute, return that
	if node:canExecute() then
		local ctx = CommandContext.new(argsSoFar, source, node)
		return ParseResults.new(ctx, errors, remaining)
	end

	-- Complete failure - return a parse result with all errors
	local ctx = CommandContext.new(argsSoFar, source, node);
	return ParseResults.new(ctx, errors, remaining)
end

return CommandDispatcher