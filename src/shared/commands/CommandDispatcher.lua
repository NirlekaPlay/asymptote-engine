--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function CommandDispatcher.parse<S>(self: CommandDispatcher<S>, input: string, source: S): (CommandContext<S>?, string?)
	-- Try to parse, collecting ALL possible results
	local results = self:tryParseAll(self.root, input, source, {})
	
	if #results == 0 then
		return nil, "No valid parse found"
	end
	
	-- Pick the result that consumed the most input
	table.sort(results, function(a: any, b: any)
		return #a.remaining < #b.remaining
	end)
	
	return results[1].context, results[1].remaining
end

function CommandDispatcher.tryParseAll<S>(
	self: CommandDispatcher<S>,
	node: CommandNode<S>,
	remaining: string,
	source: S,
	argsSoFar: {[string]: CommandNode<S>}
): {{context: CommandContext<S>, remaining: string}}
	
	remaining = remaining:gsub("^%s+", "")
	
	if remaining == "" then
		-- End of input - return this parse if node can execute
		if node:canExecute() then
			local ctx = CommandContext.new(argsSoFar, source);
			(ctx :: any).currentNode = node
			return {{context = ctx, remaining = ""}}
		end
		return {}
	end
	
	local allResults = {}
	local nextWord = remaining:match("^%S+") :: string
	
	-- Try literal children
	local literalChild = node:getChild(nextWord)
	if literalChild and literalChild.nodeType == "literal" then
		local newRemaining = remaining:sub(#nextWord + 1):gsub("^%s+", "")
		local targetNode = literalChild.redirect or literalChild
		local results = self:tryParseAll(targetNode, newRemaining, source, argsSoFar)
		for _, r in results do
			table.insert(allResults, r)
		end
	end
	
	-- Try ALL argument children (not just first match!)
	for _, child in node.children do
		if child.nodeType == "argument" and child.argumentType then
			local success, value, consumed: number = pcall(child.argumentType.parse, child.argumentType, remaining)
			if success then
				local newArgs = table.clone(argsSoFar)
				newArgs[child.name] = value
				local newRemaining = remaining:sub(consumed + 1):gsub("^%s+", "")
				local targetNode = child.redirect or child
				
				-- Recursively try to parse rest
				local results = self:tryParseAll(targetNode, newRemaining, source, newArgs)
				for _, r in results do
					table.insert(allResults, r)
				end
			end
		end
	end
	
	-- If current node can execute, also consider stopping here
	if node:canExecute() and #allResults == 0 then
		local ctx = CommandContext.new(argsSoFar, source);
		(ctx :: any).currentNode = node
		return {{context = ctx, remaining = remaining}}
	end
	
	return allResults
end

function CommandDispatcher.execute<S>(self: CommandDispatcher<S>, input: string, source: S): number
	local context, remaining = self:parse(input, source)
	
	if not context then
		error("Failed to parse command: " .. input)
	end
	
	if remaining and remaining ~= "" then
		error("Unknown command or arguments: " .. remaining)
	end
	
	local currentNode = (context :: any).currentNode
	if not currentNode or not currentNode:canExecute() then
		error("No command found for: " .. input)
	end
	
	return currentNode.command(context)
end

return CommandDispatcher