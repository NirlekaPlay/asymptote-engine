--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local ItemArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.ItemArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local SpellCorrectionSuggestion = require(ReplicatedStorage.shared.commands.context.SpellCorrectionSuggestion)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local INF = math.huge

local GiveCommand = {}

local TOOLS_PER_INST = {
	["fbb"] = ServerStorage.Tools["FB Beryl"],
	["bob_spawner"] = ServerStorage.Tools["Bob Spawner"],
	["c4"] = ReplicatedStorage.ExplFolder["Remote Explosive"],
	["f3x"] = ServerStorage.Tools["F3X"]
} :: { [string]: Instance }

local TOOLS_NAME_LIST: { string } = {}
for toolName in TOOLS_PER_INST do
	table.insert(TOOLS_NAME_LIST, toolName)
end

local ATTRIBUTE_HANDLERS = {
	fbb = {
		mags = function(item: Instance, value: any)
			item.settings.magleft.Value = value
		end,
		fireInterval = function(item: Instance, value: any)
			item.settings.speed.Value = value
		end,
		magCapacity = function(item: Instance, value: any)
			item.settings.maxmagcapacity.Value = value
		end,
	},
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

local function applyAttributes(item: Instance, itemName: string, attributes: {[string]: any})
	local handlers = ATTRIBUTE_HANDLERS[itemName]
	if not handlers or not attributes then return end
	
	for attrName, attrValue in pairs(attributes) do
		if attrValue == "inf" then
			attrValue = INF
		end
		local handler = handlers[attrName]
		if handler then
			handler(item, attrValue)
		else
			warn(`Unknown attribute '{attrName}' for item '{itemName}'`)
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
	
	local itemInst = TOOLS_PER_INST[itemName]
	if not itemInst then
		local suggest = SpellCorrectionSuggestion.didYouMean(itemName, TOOLS_NAME_LIST)
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
	end
	
	return #targets
end

return GiveCommand