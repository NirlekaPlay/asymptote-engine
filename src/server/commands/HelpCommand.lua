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
				local availableCommands = dispatcher:getAllUsage(dispatcher.root, source, false)
				
				local helpText = "Available commands:\n"
				for i, command in ipairs(availableCommands) do
					helpText = helpText .. "/" .. command .. "\n"
				end
				
				-- Remove trailing newline
				helpText = helpText:sub(1, -2)
				
				c:getSource():sendSuccess(MutableTextComponent.literal(helpText))
				
				return #availableCommands
			end)
			:andThen(
				CommandHelper.argument("command", StringArgumentType.string())
					:executes(function(c)
						local source = c:getSource()
						local commandName = c:getArgument("command")
						
						local commandNode = dispatcher.root:getChild(commandName)
						if not commandNode then
							c:getSource():sendFailure(
								MutableTextComponent.literal(`'{commandName}' is not a valid command.`)
							)
							return 0
						end
						
						local commandsDetail = dispatcher:getAllUsage(commandNode, source, false)
						local helpText = `Command tree for '{commandName}':\n`
						for i, command in ipairs(commandsDetail) do
							helpText = helpText .. "/" .. commandName .. " " .. command .. "\n"
						end

						helpText = helpText:sub(1, -2)
						
						c:getSource():sendSuccess(MutableTextComponent.literal(helpText))

						return 1
					end)
			)
	)

	dispatcher:register(
		CommandHelper.literal("?")
			:redirect(helpNode)
	)
end

return HelpCommand