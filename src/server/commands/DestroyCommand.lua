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

local DestroyCommand = {}

function DestroyCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("destroy")
			:andThen(
				CommandHelper.argument("victims", EntityArgument.entities())
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "victims")
						local counts = DestroyCommand.destroyAllTargets(c, targets)
						return counts
					end)
			)
	)
end

function DestroyCommand.destroyAllTargets(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, targets: {Instance}): number
	local count = 0
	for _, inst in ipairs(targets) do 
		if inst:IsA("Player") then
			warn(`Destroy command: Cannot attempt to destroy {inst}, as its a Player.`)
			continue
		else
			inst:Destroy()
			local targetNameComp: MutableTextComponent.MutableTextComponent = MutableTextComponent.literal("")

			targetNameComp:appendComponent(
				MutableTextComponent.literal(`{inst.Name}`)
					:withStyle(
						TextStyle.empty()
							:withItalic(true)
							:withBold(true)
							:withColor(NamedTextColors.DARK_AQUA)
					)
			)
			
			context:getSource():sendSuccess(
				MutableTextComponent.literal(`Destroyed `)
					:appendComponent(
							targetNameComp
					)
			)
		end
	end

	return count
end

return DestroyCommand