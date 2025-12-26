--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.world.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local SpellCorrectionSuggestion = require(ReplicatedStorage.shared.commands.suggestion.SpellCorrectionSuggestion)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local VALID_PACKETS = {
	["recent_path"] = true
}

local function getAvailablePacketNames(): {string}
	local packets = {}
	local i = 0
	for packetName in VALID_PACKETS :: {[string]:true} do
		i += 1
		packets[i] = packetName
	end
	return packets
end

local PacketCommand = {}

function PacketCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("packet")
			:andThen(
				CommandHelper.argument("packetName", StringArgumentType.string())
					:andThen(
						CommandHelper.argument("allow", BooleanArgumentType.bool())
							:executes(PacketCommand.setPacket)
					)
			)
	)
end

function PacketCommand.setPacket(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local packetName = StringArgumentType.getString(c, "packetName")
	local allow = BooleanArgumentType.getBool(c, "allow")

	if packetName == "recent_path" then
		Level:getSoundDispatcher():setDebugSendDebugPackets(allow)
		if allow then
			c:getSource():sendSuccess(
				MutableTextComponent.literal("You can now view the recently computed path")
			)
		else
			c:getSource():sendSuccess(
				MutableTextComponent.literal("Further packets of recently computed paths will not be sent")
			)
		end
	else
		local allTools = getAvailablePacketNames()
		local suggest = SpellCorrectionSuggestion.didYouMean(packetName, allTools)
		local message = MutableTextComponent.literal(`'{packetName}' is not a valid packet name! `)
		if suggest then
			message:appendString(suggest)
		end
		c:getSource():sendFailure(message)
		return 0
	end

	return 1
end

return PacketCommand