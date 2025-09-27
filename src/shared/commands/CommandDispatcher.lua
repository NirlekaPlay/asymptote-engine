--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

--[=[
	@class CommandDispatcher

	The core command CommandDispatcher, for registering, parsing, and executing commands.
]=]
local CommandDispatcher = {}
CommandDispatcher.__index = CommandDispatcher

export type CommandDispatcher = typeof(setmetatable({} :: {
	root: CommandNode
}, CommandDispatcher))

type CommandNode = CommandNode.CommandNode
type CommandContext = CommandContext.CommandContext
type LiteralArgumentBuilder = LiteralArgumentBuilder.LiteralArgumentBuilder

--[=[
	Creates a new `CommandDispatcher` with an empty command tree.
]=]
function CommandDispatcher.new(): CommandDispatcher
	return setmetatable({ root = CommandNode.new("", "literal", nil) }, CommandDispatcher)
end

function CommandDispatcher.register(self: CommandDispatcher, command: LiteralArgumentBuilder): CommandNode
	local node = command:build()
	self.root:addChild(node)
	return node
end

function CommandDispatcher.parse(self: CommandDispatcher, input: string, source: any): (CommandContext?, string?)
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
		else
			-- Try argument matches
			for _, child in currentNode.children do
				if child.nodeType == "argument" and child.argumentType then
					local success, value, consumed = pcall(child.argumentType.parse, remaining)
					if success then
						context.arguments[child.name] = value
						currentNode = child
						remaining = remaining:sub(consumed + 1):gsub("^%s+", "")
						found = true
						break
					end
				end
			end
		end
		
		if not found then
			break
		end
	end
	
	-- Store current node in context for execution
	(context :: any).currentNode = currentNode
	return context, remaining
end

function CommandDispatcher.execute(self: CommandDispatcher, input: string, source: any): number
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