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
function CommandDispatcher.new(): CommandDispatcher<any>
	return setmetatable({
		root = CommandNode.new("", "literal", nil),
		consumer = EMPTY_RESULT_CONSUMER
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
	local context = CommandContext.new({}, source)
	local remaining = input:gsub("^%s+", "") -- trim leading whitespace
	local currentNode = self.root
	
	while remaining ~= "" do
		local found = false
		local nextWord = remaining:match("^%S+")
		if not nextWord then break end
		
		-- Try literal matches first
		local literalChild = currentNode:getChild(nextWord)
		if literalChild and literalChild.nodeType == "literal" then
			currentNode = literalChild
			remaining = remaining:sub(nextWord:len() + 1):gsub("^%s+", "")
			found = true
			
			-- Handle redirect immediately after matching
			if currentNode.redirect then
				currentNode = currentNode.redirect
			end
			
		else
			-- Try argument matches
			for _, child in currentNode.children do
				if child.nodeType == "argument" and child.argumentType then
					local success, value, consumed: number = pcall(child.argumentType.parse, remaining)
					if success then
						context.arguments[child.name] = value
						currentNode = child
						remaining = remaining:sub(consumed + 1):gsub("^%s+", "")
						found = true
						
						-- Handle redirect for argument nodes too
						if currentNode.redirect then
							currentNode = currentNode.redirect
						end
						
						break
					end
				end
			end
		end
		
		if not found then
			break
		end
	end
	
	(context :: any).currentNode = currentNode
	return context, remaining
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