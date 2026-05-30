--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local EntityType = require(ServerScriptService.server.world.entity.registry.EntityType)
local CommandSourceStack = require(ReplicatedStorage.shared.commands.asymptote.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local SummonCommand = {}

function SummonCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local summonNode = dispatcher:register(
		CommandHelper.literal("summon")
			:andThen(
				CommandHelper.argument("entityName", StringArgumentType.word())
					:executes(function(context): number
						local specifiedEntityName = StringArgumentType.getString(context, "entityName")
						local entityType = EntityType.getEntityTypeByName(specifiedEntityName)
						if not entityType then
							error(`No such entity type of name '{specifiedEntityName}'`)
						end

						return SummonCommand.spawnEntity(context:getSource(), entityType, context:getSource():getPosition())
					end)
					:andThen(
						CommandHelper.argument("pos", Vector3ArgumentType.vec3())
							:executes(function(context): number
								local pos = Vector3ArgumentType.resolveAndGetVec3(context, "pos", context:getSource())
								local specifiedEntityName = StringArgumentType.getString(context, "entityName")
								local entityType = EntityType.getEntityTypeByName(specifiedEntityName)
								if not entityType then
									error(`No such entity type of name '{specifiedEntityName}'`)
								end

								return SummonCommand.spawnEntity(context:getSource(), entityType, pos)
							end)
							:andThen(
								CommandHelper.argument("attributes", JsonArgumentType.jsonObject())
									:executes(function(context)
										local json = JsonArgumentType.getJson(context, "attributes")
										local pos = Vector3ArgumentType.resolveAndGetVec3(context, "pos", context:getSource())
										local specifiedEntityName = StringArgumentType.getString(context, "entityName")
										local entityType = EntityType.getEntityTypeByName(specifiedEntityName)
										if not entityType then
											error(`No such entity type of name '{specifiedEntityName}'`)
										end

										return SummonCommand.spawnEntity(context:getSource(), entityType, pos, json)
									end)
							)
					)
			)
	)

	dispatcher:register(
		CommandHelper.literal("spawn")
			:redirect(summonNode :: CommandNode.CommandNode<CommandSourceStack.CommandSourceStack>)
	)
end

function SummonCommand.createEntity(source: CommandSourceStack.CommandSourceStack, entityType: EntityType.EntityType<any>, pos: Vector3, json: {[string]:any}?): ()
	local level = source:getLevel()
	local entity = entityType.create(level)
	if json then
		for name, v in json do
			entity:setAttribute(name, v)
		end
	end
	entity:finalizeSpawn()
	entity:setPosToCFrame(CFrame.new(pos))
	level:addFreshEntity(entity)
end

function SummonCommand.spawnEntity(source: CommandSourceStack.CommandSourceStack, entityType: EntityType.EntityType<any>, pos: Vector3, json: {[string]:any}): number
	SummonCommand.createEntity(source, entityType, pos, json)
	source:sendSuccess(MutableTextComponent.literal(`Successfully summoned entity.`))
	return 1
end

return SummonCommand