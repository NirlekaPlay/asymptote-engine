--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local HighlightCommand = {}

local HIGHLIGHT_INST_NAME = "CmdHighlight"

function HighlightCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	-- Create the full command node
	local boolNode = RequiredArgumentBuilder.new("bool", BooleanArgumentType.bool())
		:executes(function(c)
			local flag = c:getArgument("bool") :: boolean
			return HighlightCommand.executeHighlight(c, flag)
		end)
	
	-- Create the entities node
	local entitiesNode = RequiredArgumentBuilder.new("entities", EntitySelectorParser.entities())
		:andThen(boolNode)
		:executes(function(c)
			-- Default to true when no boolean is provided
			return HighlightCommand.executeHighlight(c, true)
		end)
	
	-- Register the main command
	dispatcher:register(
		LiteralArgumentBuilder.new("highlight")
			:andThen(entitiesNode)
	)
end

function HighlightCommand.executeHighlight<S>(context: CommandContext.CommandContext<S>, flag: boolean): number
	local selectorData = context:getArgument("entities")
	local source = context:getSource()
	local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
	
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
			elseif flag then
				local newHighlight = Instance.new("Highlight")
				newHighlight.Name = HIGHLIGHT_INST_NAME
				newHighlight.Adornee = targetChar
				newHighlight.Parent = targetChar
			end
		end
	end
	
	return #targets
end

return HighlightCommand