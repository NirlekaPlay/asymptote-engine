--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local HelpCommand = {}

function HelpCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	local helpNode = dispatcher:register(
		LiteralArgumentBuilder.new("help")
			:executes(function(c)
				local source = c:getSource()
				local availableCommands = dispatcher:getAllUsage(dispatcher.root, source, false)
				
				local helpText = "Available commands:\n"
				for i, command in ipairs(availableCommands) do
					helpText = helpText .. "/" .. command .. "\n"
				end
				
				-- Remove trailing newline
				helpText = helpText:sub(1, -2)
				
				TypedRemotes.ClientBoundChatMessage:FireClient(source, {
					literalString = helpText, 
					type = "plain"
				})
				
				return #availableCommands
			end)
			:andThen(
				RequiredArgumentBuilder.new("command", StringArgumentType)
					:executes(function(c)
						local source = c:getSource()
						local commandName = c:getArgument("command")
						
						local commandNode = dispatcher.root:getChild(commandName)
						if not commandNode then
							error(`'{commandName}' is not a valid command.`)
						end
						
						local commandsDetail = dispatcher:getAllUsage(commandNode, source, false)
						local helpText = `Command tree for '{commandName}':\n`
						for i, command in ipairs(commandsDetail) do
							helpText = helpText .. "/" .. commandName .. " " .. command .. "\n"
						end

						helpText = helpText:sub(1, -2)
						
						TypedRemotes.ClientBoundChatMessage:FireClient(source, {
							literalString = helpText, 
							type = "plain"
						})
					end)
			)
	)

	dispatcher:register(
		LiteralArgumentBuilder.new("?")
			:redirect(helpNode)
	)
end

return HelpCommand