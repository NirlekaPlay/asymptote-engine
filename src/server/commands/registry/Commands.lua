--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CellCommand = require(ServerScriptService.server.commands.CellCommand)
local DestroyCommand = require(ServerScriptService.server.commands.DestroyCommand)
local ForceFieldCommand = require(ServerScriptService.server.commands.ForceFieldCommand)
local GiveCommand = require(ServerScriptService.server.commands.GiveCommand)
local HelpCommand = require(ServerScriptService.server.commands.HelpCommand)
local HighlightCommand = require(ServerScriptService.server.commands.HighlightCommand)
local KillCommand = require(ServerScriptService.server.commands.KillCommand)
local QuoteOfTheDayCommand = require(ServerScriptService.server.commands.QuoteOfTheDayCommand)
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local SummonCommand = require(ServerScriptService.server.commands.SummonCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local TeleportCommand = require(ServerScriptService.server.commands.TeleportCommand)
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local GetEntityPosition = require(ServerScriptService.server.commands.util.GetEntityPosition)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

type CommandContext<S> = CommandContext.CommandContext<S>
type CommandDispatcher = CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>
type CommandNode<S> = CommandNode.CommandNode<S>

local dispatcher = CommandDispatcher.new() :: CommandDispatcher
local chattedConnectionsPerPlayer: { [Player]: RBXScriptConnection } = {}

local Commands = {}

function Commands.register()
	RestartServerCommand.register(dispatcher)
	TagCommand.register(dispatcher)
	KillCommand.register(dispatcher)
	TeleportCommand.register(dispatcher)
	HighlightCommand.register(dispatcher)
	DestroyCommand.register(dispatcher)
	ForceFieldCommand.register(dispatcher)
	SummonCommand.register(dispatcher)
	GiveCommand.register(dispatcher)
	HelpCommand.register(dispatcher)
	QuoteOfTheDayCommand.register(dispatcher)
	CellCommand.register(dispatcher)
end

function Commands.getDispatcher(): CommandDispatcher
	return dispatcher
end

--

function Commands.performCommand(input: string, source: CommandSourceStack.CommandSourceStack): ()
	-- Remove leading slash if present
	input = input:sub(1, 1) == "/" and input:sub(2) or input

	local parseResults = dispatcher:parse(input, source)

	local success, errorMsg = Commands.finishParsing(parseResults, source)
	
	if not success and errorMsg then
		source:sendFailure(
			MutableTextComponent.literal(errorMsg)
		)
		return
	end
	
	success, errorMsg = pcall(function()
		return dispatcher:executeParsed(parseResults)
	end)
	
	if not success then
		source:sendFailure(
			MutableTextComponent.literal("Command execution failed: " .. tostring(errorMsg))
		)
	end
end

function Commands.finishParsing(
	parsed: ParseResults.ParseResults<CommandSourceStack.CommandSourceStack>,
	source: CommandSourceStack.CommandSourceStack
): (boolean, string?)
	local remaining = parsed:getRemaining()
	local errors = parsed:getErrors()
	
	-- Check if there's unparsed input remaining
	if remaining ~= "" then
		-- Count errors to determine what message to show
		local errorCount = 0
		local singleError = nil
		
		for node, err in pairs(errors) do
			errorCount = errorCount + 1
			singleError = err
		end
		
		-- If exactly one error, show the specific error message
		if errorCount == 1 then
			return false, singleError
		else
			-- Multiple errors or no errors = generic message
			local context = parsed:getContext()
			if not context or not context.currentNode then
				return false, "Unknown command"
			else
				return false, "Unknown argument at: " .. remaining
			end
		end
	end
	
	-- Check if we found an executable command
	local context = parsed:getContext()
	if not context or not context.currentNode or not context.currentNode.command then
		return false, "Unknown command"
	end
	
	-- Validation passed!
	return true, nil
end

--

function Commands.onPlayerAdded(player: Player): ()
	local chattedConn = player.Chatted:Connect(function(str)
		Commands.onPlayerChatted(str, player)
	end)

	chattedConnectionsPerPlayer[player] = chattedConn
end

function Commands.onPlayerRemoving(player: Player): ()
	if chattedConnectionsPerPlayer[player] then
		chattedConnectionsPerPlayer[player]:Disconnect()
		chattedConnectionsPerPlayer[player] = nil
	end
end

function Commands.onPlayerChatted(str: string, player: Player): ()
	local flag = str:sub(1, 1) == "/"
	if not flag then
		return
	end

	local source = CommandSourceStack.new(
		{
			sendSystemMessage = function(_, component: MutableTextComponent.MutableTextComponent)
				TypedRemotes.ClientBoundChatMessage:FireClient(player, {
					content = component:serialize()
				})
			end
		},
		player,
		GetEntityPosition(player) or Vector3.zero,
		player.DisplayName,
		player.Name
	)
	
	-- Use performCommand instead of execute directly
	Commands.performCommand(str:sub(2), source)
end

Players.PlayerAdded:Connect(Commands.onPlayerAdded)
Players.PlayerRemoving:Connect(Commands.onPlayerRemoving)

return Commands