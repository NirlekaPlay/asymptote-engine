--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local VariableCommand = {}

function VariableCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local varCmdNode = dispatcher:register(
		CommandHelper.literal("variable")
			:andThen(
				CommandHelper.literal("set")
					:andThen(
						CommandHelper.argument("name", StringArgumentType.word())
							:andThen(
								CommandHelper.argument("value", StringArgumentType.greedyString())
									:executes(function(context): number
										local name = context:getArgument("name")
										local rawValue = context:getArgument("value")
										
										local convertedValue
										if rawValue == "true" then convertedValue = true
										elseif rawValue == "false" then convertedValue = false
										elseif tonumber(rawValue) then convertedValue = tonumber(rawValue)
										elseif rawValue == "nil" then convertedValue = nil
										else convertedValue = rawValue end

										GlobalStatesHolder.setState(name, convertedValue)
										context:getSource():sendSuccess(MutableTextComponent.literal(`Set {name} to {tostring(convertedValue)}`))
										return 1
									end)
							)
					)
			)
			:andThen(
				CommandHelper.literal("list")
					:executes(VariableCommand.list)
			)
	)

	dispatcher:register(
		CommandHelper.literal("var")
			:redirect(varCmdNode)
	)
end

function VariableCommand.list(context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local varsSet = GlobalStatesHolder.getAllStatesReference()
	local list = MutableTextComponent.literal("")

	local sortedNames: {string} = {}
	for varName in varsSet do
		table.insert(sortedNames, varName)
	end

	table.sort(sortedNames)

	for _, varName in sortedNames do
		local varVal = varsSet[varName]
		list:appendComponent(
			MutableTextComponent.literal(`{varName}: `)
		)

		if varVal == true then
			list:appendComponent(
				MutableTextComponent.literal("true")
					:withStyle(
						TextStyle.empty()
							:withColor(
								TextColor.fromColor3(Color3.fromHex("#54FF54"))
							)
					)
			)
		elseif varVal == false then
			list:appendComponent(
				MutableTextComponent.literal("false")
					:withStyle(
						TextStyle.empty()
							:withColor(
								NamedTextColors.RED
							)
					)
			)
		elseif varVal == nil then
			list:appendComponent(
				MutableTextComponent.literal("nil")
					:withStyle(
						TextStyle.empty()
							:withColor(
								TextColor.fromColor3(Color3.fromHex("#996600"))
							)
					)
			)
		elseif type(varVal) == "number" then
			list:appendComponent(
				MutableTextComponent.literal(tostring(varVal))
					:withStyle(
						TextStyle.empty()
							:withColor(
								NamedTextColors.DARK_AQUA
							)
					)
			)
		else
			list:appendComponent(
				MutableTextComponent.literal(tostring(varVal))
					:withStyle(
						TextStyle.empty()
							:withColor(
								TextColor.fromColor3(Color3.fromHex("#3b3b3b"))
							)
					)
			)
		end

		list:appendString("\n")
	end

	context:getSource():sendSuccess(list)

	return 1
end

return VariableCommand