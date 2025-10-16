--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local SummonCommand = {}

local NAMES_PER_ENTITIES = {
	bob = ServerStorage:FindFirstChild("REFERENCE_BOB"),
	jeia = ServerStorage:FindFirstChild("REFERENCE_JEIA"),
	envvy = ServerStorage:FindFirstChild("REFERENCE_ENVVY"),
	andrew = ServerStorage:FindFirstChild("REFERENCE_ANDREW")
}

function SummonCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local summonNode = dispatcher:register(
		CommandHelper.literal("summon")
			:andThen(
				CommandHelper.argument("entityName", StringArgumentType.word())
					:executes(SummonCommand.summon)
			)
			:andThen(
				CommandHelper.literal("list")
					:executes(SummonCommand.list)
			)
	)

	dispatcher:register(
		CommandHelper.literal("spawn")
			:redirect(summonNode :: CommandNode.CommandNode<CommandSourceStack.CommandSourceStack>)
	)
end

function SummonCommand.summon(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local entityName = StringArgumentType.getString(c, "entityName")
	local entityInst = NAMES_PER_ENTITIES[entityName] :: Model
	if not entityInst then
		c:getSource():sendFailure(MutableTextComponent.literal(`'{entityName}' is not a valid entity name!`))
		return 0
	end
	local playerSource = c:getSource():getPlayerOrThrow()
	local playerChar = playerSource.Character
	local toCframe: CFrame

	if not playerChar then
		c:getSource():sendFailure(MutableTextComponent.literal(`Player {playerSource.Name} has no character!`))
		return 0
	end

	toCframe = (playerChar.PrimaryPart :: BasePart).CFrame

	local entityInstClone = entityInst:Clone()
	entityInstClone:PivotTo(toCframe)
	entityInstClone.Parent = workspace

	return 1
end

function SummonCommand.list(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local listComponent = MutableTextComponent.literal("Available entity names to summon are:\n")
	
	local count = 0
	for entityName, entityInst in pairs(NAMES_PER_ENTITIES) do
		listComponent:appendComponent(
			MutableTextComponent.literal(entityName :: string .. "\n")
				:withStyle(
					TextStyle.empty()
						:withBold(true)
						:withItalic(true)
						:withColor(NamedTextColors.YELLOW))
		)
	end

	c:getSource():sendSuccess(listComponent)

	return count
end

return SummonCommand