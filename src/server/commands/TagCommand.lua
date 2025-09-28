--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local TagCommand = {}

function TagCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("tag")
			:andThen(
				LiteralArgumentBuilder.new("list")
					:executes(TagCommand.listAllTags)
			)
	)
end

function TagCommand.listAllTags(c: CommandContext.CommandContext<Player>): number
	local source = c:getSource()
	local allTags = CollectionService:GetAllTags()
	table.sort(allTags)

	local allTagsText = "All tags registered in CollectionService:\n"
	for i, command in ipairs(allTags) do
		allTagsText = allTagsText .. command .. "\n"
	end

	allTagsText = allTagsText:sub(1, -2)

	TypedRemotes.ClientBoundChatMessage:FireClient(source, {
		literalString = allTagsText,
		type = "plain"
	})

	return #allTags
end

return TagCommand