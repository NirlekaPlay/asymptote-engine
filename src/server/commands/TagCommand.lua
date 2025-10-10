--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local TagCommand = {}

function TagCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("tag")
			:andThen(
				CommandHelper.literal("list")
					:executes(TagCommand.listAllTags)
			)
	)
end

function TagCommand.listAllTags(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	local source = c:getSource()
	local allTags = CollectionService:GetAllTags()
	if next(allTags) == nil then
		source.source:sendSystemMessage(MutableTextComponent.literal("It appears there is no tags found in CollectionService..."))
		return 0
	end
	table.sort(allTags)

	local allTagsText = "All tags registered in CollectionService:\n"
	for i, command in ipairs(allTags) do
		allTagsText = allTagsText .. command .. "\n"
	end

	allTagsText = allTagsText:sub(1, -2)

	source:sendSuccess(MutableTextComponent.literal(allTagsText))

	return #allTags
end

return TagCommand