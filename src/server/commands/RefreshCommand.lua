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

local RefreshCommand = {}

function RefreshCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("refresh")
			:executes(function(c)
				return RefreshCommand.refresh(c, {c:getSource():getPlayerOrThrow()})
			end)
			:andThen(
				CommandHelper.argument("victims", EntityArgument.entities())
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "victims")
						return RefreshCommand.refresh(c, targets)
					end)
			)
	)
end

function RefreshCommand.refresh(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, targets: {Instance}): number
	for _, target in targets do
		if not target:IsA("Player") then
			continue
		end

		task.spawn(function()
			target:LoadCharacterAsync()

			local targetNameComp: MutableTextComponent.MutableTextComponent = MutableTextComponent.literal("")

			targetNameComp:appendComponent(
				MutableTextComponent.literal(`@{target.Name}`)
					:withStyle(
						TextStyle.empty()
							:withItalic(true)
							:withBold(true)
							:withColor(NamedTextColors.DARK_AQUA)
					)
			)
			if target.Name ~= target.DisplayName then
				targetNameComp:appendString(" (a.k.a)")
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
								:withColor(NamedTextColors.YELLOW)
						)
				)

				c:getSource():sendSuccess(
					MutableTextComponent.literal(`Killed `)
						:appendComponent(
								targetNameComp
						)
				)
			end
		end)
	end
	
	return #targets
end

return RefreshCommand