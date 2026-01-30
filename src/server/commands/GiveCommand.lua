--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local ItemArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.ItemArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local SpellCorrectionSuggestion = require(ReplicatedStorage.shared.commands.suggestion.SpellCorrectionSuggestion)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local INF = math.huge

local GiveCommand = {}

local TOOLS_PER_INST = {} :: { [string]: Instance }

local toolsFolder = ServerStorage:FindFirstChild("Tools")
if toolsFolder then
	TOOLS_PER_INST["fbb"] = toolsFolder:FindFirstChild("FB Beryl")
	TOOLS_PER_INST["bob_spawner"] = toolsFolder:FindFirstChild("Bob Spawner")
	TOOLS_PER_INST["f3x"] = toolsFolder:FindFirstChild("F3X")
end

local explFolder = ReplicatedStorage:FindFirstChild("ExplFolder")
if explFolder then
	TOOLS_PER_INST["c4"] = explFolder:FindFirstChild("Remote Explosive")
end

local ATTRIBUTE_HANDLERS = {
	c4 = {
		radius = function(item: Instance, value: any)
			require(item.Settings).ExpRange = value
		end,
		maxAmount = function(item: Instance, value: any)
			require(item.Settings).MaxAmmo = value
		end,
		amount = function(item: Instance, value: any)
			item.Handle:SetAttribute("Ammo", value)
		end,
		blastPressure = function(item: Instance, value: any)
			require(item.Settings).BlastPressure = value
		end,
		plantRange = function(item: Instance, value: any)
			require(item.Settings).PlantRange = value
		end,
	}
}

local TOOL_SEARCH_LOCATIONS = {
	ServerStorage:FindFirstChild("Tools"),
	ServerStorage,
	StarterPack
}

local function findToolByName(toolName: string): Instance?
	local predefined = TOOLS_PER_INST[toolName]
	if predefined then
		return predefined
	end
	
	for _, location in ipairs(TOOL_SEARCH_LOCATIONS) do
		if not location then continue end
		
		local tool = location:FindFirstChild(toolName)
		if tool and (tool:IsA("Tool") or tool:IsA("Model")) then
			return tool
		end
	end
	
	return nil
end

local function getAllAvailableToolNames(): { string }
	local toolNames: {string} = {}
	local seen: { [string]: boolean } = {}
	
	for toolName in TOOLS_PER_INST do
		if not seen[toolName] then
			table.insert(toolNames, toolName)
			seen[toolName] = true
		end
	end

	for _, location in ipairs(TOOL_SEARCH_LOCATIONS) do
		if not location then continue end
		
		for _, child in ipairs(location:GetChildren()) do
			if (child:IsA("Tool") or child:IsA("Model")) and not seen[child.Name] then
				table.insert(toolNames, child.Name)
				seen[child.Name] = true
			end
		end
	end
	
	return toolNames
end

local function applyAttributes(item: Instance, itemName: string, attributes: { [string]: any })
	local handlers = ATTRIBUTE_HANDLERS[itemName]
	if not attributes then
		return
	end
	
	for attrName, attrValue in pairs(attributes) do
		if attrValue == "inf" then
			attrValue = INF
		end
		local handler = handlers and handlers[attrName] or nil
		if handler then
			handler(item, attrValue)
		else
			item:SetAttribute(attrName, attrValue)
		end
	end
end

function GiveCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("give")
			:andThen(
				CommandHelper.argument("targets", EntityArgument.entities())
					:andThen(
						CommandHelper.argument("itemData", ItemArgument.item())
							:executes(GiveCommand.giveItem)
					)
			)
	)
end

function GiveCommand.giveItem(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>)
	local itemData = ItemArgument.getItemData(context, "itemData")
	local itemName = itemData.itemName
	local attributes = itemData.attributes
	
	local itemInst = findToolByName(itemName)
	if not itemInst then
		local allTools = getAllAvailableToolNames()
		local suggest = SpellCorrectionSuggestion.didYouMean(itemName, allTools)
		local message = MutableTextComponent.literal(`'{itemName}' is not a valid item name! `)
		if suggest then
			message:appendString(suggest)
		end
		context:getSource():sendFailure(message)
		return 0
	end

	local targets = EntityArgument.getEntities(context, "targets")

	for _, target in targets do
		if not target:IsA("Player") then continue end

		local itemClone = itemInst:Clone()
		
		if attributes then
			applyAttributes(itemClone, itemName, attributes)
		end
		
		itemClone.Parent = target.Backpack
		
		local playerText = MutableTextComponent.literal(""):appendComponent(
				MutableTextComponent.literal(`@{target.Name}`)
					:withStyle(
						TextStyle.empty()
							:withItalic(true)
							:withBold(true)
							:withColor(NamedTextColors.MUTED_SOFT_AQUA)
					)
			)
		
		if target.Name ~= target.DisplayName then
			playerText:appendString(" (a.k.a)")
				:withStyle(
					TextStyle.empty()
						:withItalic()
			)
			:appendComponent(
				MutableTextComponent.literal(` {target.DisplayName}`)
					:withStyle(
						TextStyle.empty()
							:withBold(true)
							:withItalic(true)
							:withColor(NamedTextColors.MUTED_LIGHT_BLUE)
					)
			)
		end

		local itemText = MutableTextComponent.literal(` {itemClone.Name}`)
			:withStyle(
				TextStyle.empty()
					:withBold(true)
					:withColor(NamedTextColors.YELLOW)
			)

		local successMessage = MutableTextComponent.literal("Gave ")
			:appendComponent(playerText)
			:appendComponent(itemText)

		context:getSource():sendSuccess(successMessage)
	end
	
	return #targets
end

return GiveCommand