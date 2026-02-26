--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

--[=[
	@class SuggestionContext
]=]
local SuggestionContext = {}
SuggestionContext.__index = SuggestionContext

export type SuggestionContext<S> = typeof(setmetatable({} :: {
	parent: CommandNode.CommandNode<S>,
	startPos: number
}, SuggestionContext))

function SuggestionContext.new<S>(parent: CommandNode.CommandNode<S>, startPos: number): SuggestionContext<S>
	return setmetatable({
		parent = parent,
		startPos = startPos
	}, SuggestionContext)
end

return SuggestionContext