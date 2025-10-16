--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local HelpCommand = {}

function HelpCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local helpNode = dispatcher:register(
		CommandHelper.literal("help")
			:executes(function(c)
				local source = c:getSource()
				local availableCommands = dispatcher:getSmartUsage(dispatcher:getRoot(), source, false)
				local count = 0
				
				local helpText = "Available commands:\n"
				for _, command in pairs(availableCommands) do
					count += 1
					helpText = helpText .. "/" .. command .. "\n"
				end
				
				-- Remove trailing newline
				helpText = helpText:sub(1, -2)
				
				c:getSource():sendSuccess(MutableTextComponent.literal(helpText))
				
				return count
			end)
			:andThen(
				CommandHelper.argument("command", StringArgumentType.greedyString())
					:executes(function(c)
						local parseResults = dispatcher:parseString(
							StringArgumentType.getString(c, "command"), c:getSource()
						)

						if next(parseResults:getContext():getNodes()) == nil then
							error("Unknown command")
						else
							local nodes = parseResults:getContext():getNodes()
							local nodesSize = #nodes
							local last = nodes[nodesSize]:getNode()
							local map = dispatcher:getSmartUsage(last, c:getSource())

							local fullUsageText = "Full command tree:\n"
							local count = 0
							for _, usage in pairs(map) do
								count += 1
								fullUsageText ..= "/" .. parseResults:getReader():getString() .. " " .. usage .. "\n"
							end

							fullUsageText = fullUsageText:sub(1, -2)

							c:getSource():sendSuccess(MutableTextComponent.literal(fullUsageText))
							return 1
						end
					end)
			)
	)

	dispatcher:register(
		CommandHelper.literal("?")
			:redirect(helpNode)
	)
end

return HelpCommand