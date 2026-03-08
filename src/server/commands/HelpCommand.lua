--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local HelpCommand = {}

function HelpCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local helpNode = dispatcher:register(
		CommandHelper.literal("help")
			:executes(function(c)
				local availableCommands = dispatcher:getRoot():getChildren()
				local smartUsages = dispatcher:getSmartUsage(dispatcher:getRoot(), c:getSource())

				if next(availableCommands) == nil then
					c:getSource():sendSuccess(MutableTextComponent.literal("Strange... It seems like there are no commands"))
					return 0
				end

				local commandList: {
					{
						command: string,
						description: string?,
						node: CommandNode.CommandNode<CommandSourceStack.CommandSourceStack>
					}
				} = {}
				local max = 0
				for name, node in availableCommands do
					max += 1
					table.insert(commandList, {
						command = name,
						description = node:getDescription(),
						node = node
					})
				end
				
				table.sort(commandList, function(a, b)
					return a.command:lower() < b.command:lower()
				end)
				
				local helpText = MutableTextComponent.literal("Available commands:\n")
				for i, stub in commandList do
					if stub.description then
						helpText:appendString(`/{stub.command}`)
						helpText:appendComponent(
							MutableTextComponent.literal(` - {stub.description}`)
								:withStyle(
									TextStyle.empty()
										:withColor(
											NamedTextColors.LIGHT_GRAY
										)
										:withItalic(true)
								)
						)
					else
						helpText:appendString(`/{smartUsages[stub.node]}`)
					end
					if i ~= max then
						helpText:appendString("\n")
					end
				end
				
				c:getSource():sendSuccess(helpText)
				
				return max
			end)
			:andThen(
				(CommandHelper.argument :: any)("command", StringArgumentType.greedyString())
					:executes(function(c)
						local commandInput = StringArgumentType.getString(c, "command")
						local parseResults = dispatcher:parseString(commandInput, c:getSource())
						local context = parseResults:getContext()

						if next(context:getNodes()) == nil then
							error("Unknown command")
						end

						local nodes = context:getNodes()
						local targetNode = nodes[#nodes]:getNode()
						local usageMap = dispatcher:getSmartUsage(targetNode, c:getSource())
						
						local helpResponse = MutableTextComponent.literal("")
						local hasDescriptions = false

						local syntaxHeader = MutableTextComponent.literal("Syntax:\n")
						
						for node, usage in usageMap do
							local desc = node:getDescription()
							
							if not desc then
								local current = node
								while current and not desc do
									local _, firstChild = next(current:getChildren())
									if firstChild then
										desc = firstChild:getDescription()
										current = firstChild
									else break end
								end
							end

							if desc then
								hasDescriptions = true
								-- "/cmd sub - Description"
								syntaxHeader:appendString(`    /{commandInput} {usage} `)
								syntaxHeader:appendComponent(
									MutableTextComponent.literal(`- {desc}\n`)
										:withStyle(TextStyle.empty()
											:withColor(NamedTextColors.LIGHT_GRAY)
											:withItalic(true)
										)
								)
							end
						end

						local treeSection = MutableTextComponent.literal("\nFull command tree:")
						local count = 0
						local total = 0
						for _ in usageMap do total += 1 end

						for _, usage in usageMap do
							count += 1
							local line = `\n/{commandInput} {usage}`
							treeSection:appendString(line)
						end

						if hasDescriptions then
							helpResponse:appendComponent(syntaxHeader)
						end
						helpResponse:appendComponent(treeSection)

						c:getSource():sendSuccess(helpResponse)
						return 1
					end)
			)
	)

	dispatcher:register(
		CommandHelper.literal("?")
			:redirect(helpNode)
	)
end

return HelpCommand