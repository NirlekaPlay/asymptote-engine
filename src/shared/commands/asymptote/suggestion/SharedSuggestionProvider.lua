--!strict

local Players = game:GetService("Players")

--[=[
	@class SharedSuggestionProvider
]=]
local SharedSuggestionProvider = {}
SharedSuggestionProvider.__index = SharedSuggestionProvider

export type SharedSuggestionProvider = typeof(setmetatable({} :: {
	localPlayer: Player
}, SharedSuggestionProvider))

function SharedSuggestionProvider.new(localPlayer: Player): SharedSuggestionProvider
	return setmetatable({
		localPlayer = localPlayer
	}, SharedSuggestionProvider)
end

--[=[
	Returns `true` if the given `value` is an instance of `SharedSuggestionProvider`.
]=]
function SharedSuggestionProvider.isInstance(value: any): boolean
	return getmetatable(value) == SharedSuggestionProvider
end

--[=[
	Returns `value` but now typed as `SharedSuggestionProvider`.
]=]
function SharedSuggestionProvider.getInstance(value: any): SharedSuggestionProvider
	return value
end

--[=[
	Returns an array of all players in the server.
]=]
function SharedSuggestionProvider.getOnlinePlayers(self: SharedSuggestionProvider): {Player}
	return Players:GetPlayers()
end

return SharedSuggestionProvider