--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local GreetCommand = {}

function GreetCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("greet")
			-- Path 1: /greet
			:executes(function(c)
				local sender = c:getSource():getPlayerOrThrow()
				return GreetCommand.greet(c, {sender})
			end)
			-- Path 2: /greet <target>
			:andThen(
				CommandHelper.argument("target", EntityArgument.entities())
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "target")
						return GreetCommand.greet(c, targets)
					end)
			)
	)
end

function GreetCommand.greet(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, targets: {Player}): number
	local sender = c:getSource():getPlayerOrThrow()
	local senderName = sender and sender.DisplayName or "System"

	for _, player in targets do
		local message = MutableTextComponent.literal("Hello ")
			:appendComponent(
				MutableTextComponent.literal(player.DisplayName)
					:withStyle(TextStyle.empty():withColor(NamedTextColors.YELLOW):withBold(true))
			)
			:appendString(", ")
			:appendComponent(
				MutableTextComponent.literal(senderName)
					:withStyle(TextStyle.empty():withColor(NamedTextColors.DARK_AQUA):withItalic(true))
			)
			:appendString(" says hi!")

		c:getSource():sendSuccess(message)
	end
	
	return #targets
end

return GreetCommand