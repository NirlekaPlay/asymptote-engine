--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class ItemArgument
]=]
local ItemArgument = {}
ItemArgument.__index = ItemArgument

export type ItemArgument = ArgumentType.ArgumentType<ParsedItemDataResult>

export type ParsedItemDataResult = {
	itemName: string,
	attributes: { [string]: any }?
}

function ItemArgument.item(): ItemArgument
	return setmetatable({}, ItemArgument) :: ItemArgument
end

function ItemArgument.getItemData<S>(context: CommandContext.CommandContext<S>, name: string): ParsedItemDataResult
	local itemDataArg = context:getArgument(name)
	if type(itemDataArg) ~= "table" or not (itemDataArg.itemName) then
		error(`Argument '{name}' results in a value of type {typeof(itemDataArg)}, expected ParsedItemDataResult`)
	end
	return itemDataArg :: ParsedItemDataResult
end

function ItemArgument.parse(self: ItemArgument, input: string): (ParsedItemDataResult, number)
	-- Parse item name first
	local itemName = input:match("^%S+")
	if not itemName then
		error("Expected item name")
	end
	
	local consumed = itemName:len()
	local remaining = input:sub(consumed + 1)
	
	-- Check if there's JSON attributes
	remaining = remaining:match("^%s*(.*)") -- trim whitespace
	local attributes = nil
	
	if remaining and remaining:sub(1, 1) == "{" then
		local attrData, jsonConsumed = JsonArgumentType.jsonObject():parse(remaining)
		attributes = attrData
		consumed = consumed + (input:len() - remaining:len()) + jsonConsumed
	end
	
	return {
		itemName = itemName,
		attributes = attributes
	}, consumed
end

return ItemArgument