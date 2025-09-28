--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local SummonCommand = {}

local NAMES_PER_ENTITIES = {
	bob = ServerStorage.REFERENCE_BOB,
	jeia = ServerStorage.REFERENCE_JEIA,
	envvy = ServerStorage.REFERENCE_ENVVY,
	andrew = ServerStorage.REFERENCE_ANDREW
}

function SummonCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("summon")
			:andThen(
				RequiredArgumentBuilder.new("entityName", StringArgumentType)
					:executes(SummonCommand.summon)
			)
	)
end

function SummonCommand.summon(c: CommandContext.CommandContext<Player>): number
	local entityName = c:getArgument("entityName")
	local entityInst = NAMES_PER_ENTITIES[entityName] :: Model
	if not entityInst then
		error(`{entityName} is not a valid entity name`)
	end
	local playerSource = c:getSource() :: Player
	local playerChar = playerSource.Character
	local toCframe: CFrame

	if not playerChar then
		error("Player has no character")
	end

	toCframe = playerChar.PrimaryPart.CFrame

	local entityInstClone = entityInst:Clone()
	entityInstClone:PivotTo(toCframe)
	entityInstClone.Parent = workspace

	return 1
end

return SummonCommand