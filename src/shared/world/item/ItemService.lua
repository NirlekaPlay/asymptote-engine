--!strict

local ServerStorage = game:GetService("ServerStorage")

--[=[
	@class ItemService
]=]
local ItemService = {}

function ItemService.getItemLocalizedStringName(itemId: string): string
	return (ServerStorage.Tools[itemId] :: Instance):GetAttribute("NameKey") :: string? or itemId
end

return ItemService