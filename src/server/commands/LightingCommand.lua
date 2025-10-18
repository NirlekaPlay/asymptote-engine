--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local LightingNames = require(ServerScriptService.server.world.lighting.LightingNames)
local LightingSetter = require(ServerScriptService.server.world.lighting.LightingSetter)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local SpellCorrectionSuggestion = require(ReplicatedStorage.shared.commands.suggestion.SpellCorrectionSuggestion)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local LightingCommand = {}

function LightingCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("lighting")
			:andThen(
				CommandHelper.literal("list")
					:executes(LightingCommand.listLightingConfigs)
			)
			:andThen(
				CommandHelper.literal("set")
					:andThen(
						CommandHelper.argument("lightingConfigName", StringArgumentType.greedyString())
							:executes(LightingCommand.setLigthingConfig)
					)
			)
	)
end

function LightingCommand.listLightingConfigs(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local source = c:getSource()
	local allLightingNames: { string } = {}
	for name in pairs(LightingNames :: { [string]: any }) do
		table.insert(allLightingNames, name)
	end
	table.sort(allLightingNames)

	local allTagsText = "All lighting configuration names:\n"
	for _, name in ipairs(allLightingNames) do
		allTagsText = allTagsText .. name .. "\n"
	end

	allTagsText = allTagsText:sub(1, -2)

	source:sendSuccess(MutableTextComponent.literal(allTagsText))

	return #allLightingNames
end

function LightingCommand.setLigthingConfig(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local source = c:getSource()
	local lightingConfigName = StringArgumentType.getString(c, "lightingConfigName")
	local config = (LightingNames :: any)[lightingConfigName:upper()]
	if not config then
		local allLightingNames: { string } = {}
		for name in pairs(LightingNames :: { [string]: any }) do
			table.insert(allLightingNames, name)
		end
		local suggest = SpellCorrectionSuggestion.didYouMean(lightingConfigName, allLightingNames)
		local message = MutableTextComponent.literal(`'{lightingConfigName:upper()}' is not a valid item name! `)
		if suggest then
			message:appendString(suggest)
		end
		source:sendFailure(message)
		return 0
	end

	LightingSetter.readConfig(config :: any)

	return 1
end

return LightingCommand