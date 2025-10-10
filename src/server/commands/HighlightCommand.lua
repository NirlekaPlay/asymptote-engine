--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local HighlightCommand = {}

local HIGHLIGHT_INST_NAME = "CmdHighlight"

function HighlightCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	-- Create the full command node
	local boolNode = CommandHelper.argument("bool", BooleanArgumentType.bool())
		:executes(function(c)
			local flag = BooleanArgumentType.getBool(c, "bool")
			return HighlightCommand.executeHighlight(c, flag) :: number
		end)
	
	-- Create the entities node
	local entitiesNode = CommandHelper.argument("entities", EntityArgument.entities())
		:andThen(boolNode)
		:executes(function(c)
			-- Default to true when no boolean is provided
			return HighlightCommand.executeHighlight(c, true) :: number
		end)
	
	-- Register the main command
	dispatcher:register(
		CommandHelper.literal("highlight")
			:andThen(entitiesNode)
	)
end

function HighlightCommand.executeHighlight(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, flag: boolean): number
	local targets = EntityArgument.getEntities(context, "entities")

	local numOfNonPlayers = 0
	local numOfPlayers = 0
	for _, target in targets do
		local targetChar
		if target:IsA("Player") and target.Character then
			targetChar = target.Character
		else
			targetChar = target
		end
		
		if targetChar then
			local highlight = targetChar:FindFirstChild(HIGHLIGHT_INST_NAME) :: Highlight?
			if highlight and not flag then
				highlight:Destroy()
				if target:IsA("Player") then
					numOfPlayers += 1
				else
					numOfNonPlayers += 1
				end
			elseif flag then
				local newHighlight = Instance.new("Highlight")
				newHighlight.Name = HIGHLIGHT_INST_NAME
				newHighlight.Adornee = targetChar
				newHighlight.Parent = targetChar
				if target:IsA("Player") then
					numOfPlayers += 1
				else
					numOfNonPlayers += 1
				end
			end
		end
	end

	local firstMessage: MutableTextComponent.MutableTextComponent
	if flag then
		firstMessage = MutableTextComponent.literal("Successfully applied highlight to ")
	else
		firstMessage = MutableTextComponent.literal("Successfully removed highlight from ")
	end

	firstMessage:appendComponent(
		MutableTextComponent.literal(`{numOfPlayers} `)
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.YELLOW)
			)
			:appendComponent(
				MutableTextComponent.literal(if numOfPlayers > 1 then "players " else "player ")
					:withStyle(
						TextStyle.empty()
							:withColor(NamedTextColors.DARK_AQUA)
					)
			)
	)		
	:appendString("and ")
	:appendComponent(
		MutableTextComponent.literal(`{numOfNonPlayers} `)
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.SOFT_YELLOW)
			)
	)
	:appendComponent(
		MutableTextComponent.literal("non players.")
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.MUTED_SOFT_AQUA)
			)
	)

	context:getSource():sendSuccess(firstMessage)
	
	return #targets
end

return HighlightCommand