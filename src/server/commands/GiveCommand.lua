--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local ItemArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.ItemArgument)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local INF = math.huge

local GiveCommand = {}

local TOOLS_PER_INST = {
	["fbb"] = ServerStorage.Tools["FB Beryl"],
	["bob_spawner"] = ServerStorage.Tools["Bob Spawner"],
	["c4"] = ReplicatedStorage.ExplFolder["Remote Explosive"],
	["f3x"] = ServerStorage.Tools["F3X"]
} :: { [string]: Instance }

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

function GiveCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("give")
			:andThen(
				RequiredArgumentBuilder.new("target", EntitySelectorParser.entities())
					:andThen(
						RequiredArgumentBuilder.new("itemData", ItemArgument.item())
							:executes(GiveCommand.giveItem)
					)
			)
	)
end

function GiveCommand.giveItem(context: CommandContext.CommandContext<Player>)
	local itemData = ItemArgument.getItemData(context, "itemData")
	local itemName = itemData.itemName
	local attributes = itemData.attributes
	
	local itemInst = TOOLS_PER_INST[itemName]
	if not itemInst then
		error(`'{itemName}' is not a valid item name`)
	end
	
	local selectorData = context:getArgument("target")
	local source = context:getSource()
	local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)

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