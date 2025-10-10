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

local KillCommand = {}

function KillCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("kill")
			:executes(function(c)
				return KillCommand.kill(c, {c:getSource():getPlayerOrThrow()})
			end)
			:andThen(
				CommandHelper.argument("victims", EntityArgument.entities())
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "victims")
						return KillCommand.kill(c, targets)
					end)
			)
	)
end

function KillCommand.kill(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, targets: {Instance}): number
	for _, target in targets do
		local targetName: string
		local targetChar
		if target:IsA("Player") then
			targetName = target.Name
			targetChar = target.Character
		else
			targetName = target.Name
			targetChar = target
		end
		if targetChar then
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
				local targetNameComp: MutableTextComponent.MutableTextComponent = MutableTextComponent.literal("")

				if target:IsA("Player") then
					targetNameComp:appendComponent(
						MutableTextComponent.literal(`@{targetName}`)
							:withStyle(
								TextStyle.empty()
									:withItalic(true)
									:withBold(true)
									:withColor(NamedTextColors.DARK_AQUA)
							)
					)
					:appendString(" (a.k.a)")
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
				else
					targetNameComp:appendComponent(
						MutableTextComponent.literal(`{targetName}`)
							:withStyle(
								TextStyle.empty()
									:withItalic(true)
									:withBold(true)
									:withColor(NamedTextColors.DARK_AQUA)
							)
					)
				end
				
				c:getSource():sendSuccess(
					MutableTextComponent.literal(`Killed `)
						:appendComponent(
								targetNameComp
						)
				)
			end
		end
	end
	
	return #targets
end

return KillCommand