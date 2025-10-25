--!strict

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local InsertAssetCommand = {}

function InsertAssetCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local cmd = dispatcher:register(
		CommandHelper.literal("insertasset")
			:andThen(
				CommandHelper.argument("players", EntityArgument.entities())
					:andThen(
						CommandHelper.argument("assetid", IntegerArgumentType.integer(0, 2^53))
							:executes(InsertAssetCommand.giveItem)
					)
			)
	)

	dispatcher:register(
		CommandHelper.literal("giveid")
			:redirect(cmd)
	)
end

function InsertAssetCommand.giveItem(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>)
	local assetId = IntegerArgumentType.getInteger(context, "assetid")
	local success, model: Instance = (pcall :: any)(InsertService.LoadAsset, InsertService, assetId)
	if not success then
		local message = MutableTextComponent.literal("An error occured while trying to fetch asset: ")
			:appendString(model :: any)

		context:getSource():sendFailure(message)
		return 0
	end

	local targets = EntityArgument.getEntities(context, "players")
	local itemNamesTbl: {string} = {}
	for _, child in model:GetChildren() do
		table.insert(itemNamesTbl, child.Name)
	end
	local itemNames = table.concat(itemNamesTbl)

	for _, target in targets do
		if not target:IsA("Player") then continue end

		for _, child in model:GetChildren() do
			local itemClone = child:Clone()
			itemClone.Parent = target.Backpack
		end
		
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

		local itemText = MutableTextComponent.literal(` {itemNames}`)
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

	model:Destroy()
	
	return #targets
end

return InsertAssetCommand