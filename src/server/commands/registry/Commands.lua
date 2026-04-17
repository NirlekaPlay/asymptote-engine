--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DestroyCommand = require(ServerScriptService.server.commands.DestroyCommand)
local ForceFieldCommand = require(ServerScriptService.server.commands.ForceFieldCommand)
local GiveCommand = require(ServerScriptService.server.commands.GiveCommand)
local HelpCommand = require(ServerScriptService.server.commands.HelpCommand)
local HighlightCommand = require(ServerScriptService.server.commands.HighlightCommand)
local InsertAssetCommand = require(ServerScriptService.server.commands.InsertAssetCommand)
local KillCommand = require(ServerScriptService.server.commands.KillCommand)
local LightingCommand = require(ServerScriptService.server.commands.LightingCommand)
local MapCommand = require(ServerScriptService.server.commands.MapCommand)
local QuoteOfTheDayCommand = require(ServerScriptService.server.commands.QuoteOfTheDayCommand)
local RefreshCommand = require(ServerScriptService.server.commands.RefreshCommand)
local RestartLevelCommand = require(ServerScriptService.server.commands.RestartLevelCommand)
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local SummonCommand = require(ServerScriptService.server.commands.SummonCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local TeleportCommand = require(ServerScriptService.server.commands.TeleportCommand)
local VariableCommand = require(ServerScriptService.server.commands.VariableCommand)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local GetEntityPosition = require(ServerScriptService.server.commands.util.GetEntityPosition)
local LevelAccessor = require(ServerScriptService.server.world.level.LevelAccessor)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ParseResults = require(ReplicatedStorage.shared.commands.ParseResults)
local SharedSuggestionProvider = require(ReplicatedStorage.shared.commands.asymptote.suggestion.SharedSuggestionProvider)
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local ArgumentBuilderFactory = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilderFactory)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local RootCommandNode = require(ReplicatedStorage.shared.commands.tree.RootCommandNode)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local ClientboundCommandsPacket = require(ReplicatedStorage.shared.network.game.ClientboundCommandsPacket)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

type CommandContext<S> = CommandContext.CommandContext<S>
type CommandDispatcher = CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>
type CommandNode<S> = CommandNode.CommandNode<S>
type SharedSuggestionProvider = SharedSuggestionProvider.SharedSuggestionProvider

local dispatcher = CommandDispatcher.new() :: CommandDispatcher<CommandSourceStack.CommandSourceStack>
local chattedConnectionsPerPlayer: { [Player]: RBXScriptConnection } = {}
local currentLevel: LevelAccessor.LevelAccessor

local Commands = {}

function Commands.register(level)
	currentLevel = level
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
	LightingCommand.register(dispatcher)
	InsertAssetCommand.register(dispatcher)
	RestartLevelCommand.register(dispatcher)
	RefreshCommand.register(dispatcher)
	VariableCommand.register(dispatcher)
	MapCommand.register(dispatcher)
end

function Commands.getDispatcher(): CommandDispatcher
	return dispatcher
end

--

function Commands.performCommand(input: string, source: CommandSourceStack.CommandSourceStack): ()
	-- Remove leading slash if present
	input = input:sub(1, 1) == "/" and input:sub(2) or input

	local parseResults = dispatcher:parseString(input, source)

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

	local parseErrors = Commands.getParseErrors(parsed)
	if parseErrors then
		return false, parseErrors
	end
	
	-- Validation passed!
	return true, nil
end

function Commands.getParseErrors<S>(parseResults: ParseResults.ParseResults<S>): string?
	if not parseResults:getReader():canRead() then
		return nil
	end
	
	local errors = parseResults:getErrors()
	local errorCount = 0
	for _ in errors do
		errorCount += 1
	end
	
	local input = parseResults:getReader():getString()
	
	if errorCount == 1 then
		for _, err in pairs(errors) do
			if type(err) == "table" then
				local context = input:sub(1, err.cursorPos) .. " <-- HERE"
				return err.message .. "\n" .. context
			else
				-- Fallback for old string format
				return err
			end
		end
	elseif errorCount > 1 then
		local firstError = next(errors)
		local err = errors[firstError]
		
		if type(err) == "table" then
			local context = input:sub(1, err.cursorPos) .. " <-- HERE"
			return err.message .. "\n" .. context
		else
			return err
		end
	end
	
	return parseResults:getContext():getRange():isEmpty()
		and "Unknown or incomplete command"
		or "Incorrect argument for command"
end

--

type Map<K, V> = { [K]: V }

function Commands.sendCommands(player: Player): ()
	local source = Commands.createCommandSourceStackFromPlayer(player)
	local map = {} :: Map<CommandNode<CommandSourceStack.CommandSourceStack>, CommandNode<SharedSuggestionProvider>>
	local rootCommandNode = RootCommandNode.new()

	map[dispatcher:getRoot()] = rootCommandNode
	Commands.fillUsableCommands(dispatcher:getRoot(), rootCommandNode, source, map)

	TypedRemotes.ClientboundCommandsPacket:FireClient(player, ClientboundCommandsPacket.fromRootNode(rootCommandNode):serializeToNetwork())
end

function Commands.fillUsableCommands(
	node1: CommandNode<CommandSourceStack.CommandSourceStack>,
	node2: CommandNode<SharedSuggestionProvider>,
	source: CommandSourceStack.CommandSourceStack,
	map: Map<CommandNode<CommandSourceStack.CommandSourceStack>, CommandNode<SharedSuggestionProvider>>
): ()
	for _, node in node1:getChildren() do
		if node:canUse(source) then
			local argumentBuilder = ArgumentBuilderFactory.createBuilder(node) :: ArgumentBuilder.ArgumentBuilder<CommandSourceStack.CommandSourceStack, any>
			argumentBuilder:requires(function(s)
				return true
			end)

			if argumentBuilder.command ~= nil then
				argumentBuilder:executes(function(c)
					return 0
				end)
			end

			if getmetatable(argumentBuilder) == RequiredArgumentBuilder then
				local requiredArgumentBuilder = argumentBuilder :: RequiredArgumentBuilder.RequiredArgumentBuilder<CommandSourceStack.CommandSourceStack>
				if requiredArgumentBuilder.suggestionsProvider ~= nil then
					requiredArgumentBuilder:suggests(SuggestionProviders.safelySwap(requiredArgumentBuilder.suggestionsProvider))
				end
			end

			-- FOR NOW: Don't sent the description string to the client. It adds to the size of the packet
			-- Also we don't really need it right now since the description of a node can only be seen if user calls `/help` or
			-- `/help <command>`, which is sent from the server to the client on the call.
			--[[if node:getDescription() then
				argumentBuilder:describe(node:getDescription())
			end]]

			if argumentBuilder.redirectNode ~= nil then
				argumentBuilder:redirect(map[argumentBuilder.redirectNode])
			end

			local commandNode1 = argumentBuilder:build()
			map[node] = commandNode1
			node2:addChild(commandNode1)
			if next(node:getChildren()) ~= nil then
				Commands.fillUsableCommands(node, commandNode1, source, map)
			end
		end
	end
end

--

function Commands.createCommandSourceStackFromPlayer(player: Player): CommandSourceStack.CommandSourceStack
	return CommandSourceStack.new(
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
		player.Name,
		currentLevel
	)
end

function Commands.onPlayerAdded(player: Player): ()
	local chattedConn = player.Chatted:Connect(function(str)
		Commands.onPlayerChatted(str, player)
	end)

	chattedConnectionsPerPlayer[player] = chattedConn
	Commands.sendCommands(player)
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

	local source = Commands.createCommandSourceStackFromPlayer(player)
	
	-- Use performCommand instead of execute directly
	Commands.performCommand(str:sub(2), source)
end

Players.PlayerAdded:Connect(Commands.onPlayerAdded)
Players.PlayerRemoving:Connect(Commands.onPlayerRemoving)

TypedRemotes.ServerboundPlayerSendCommand.OnServerEvent:Connect(function(player, str)
	Commands.onPlayerChatted(str, player)
end)

return Commands