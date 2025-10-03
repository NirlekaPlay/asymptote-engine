--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

--[=[
	@class JsonArgumentType

	A JSON argument type. Can accept JSON *objects*:

	```json
	{
		"name": "John Doe",
		"age": 30,
		"isEmployed": true,
		"hobbies": ["golf", "painting", "coding"],
		"address": {
			"street": "123 Main St",
			"city": "New York",
			"zip": "10001"
		}
	}
	```

	or JSON *arrays*:

	```json
	["Apple", "Grapes"]
	```
]=]
local JsonArgumentType = {}
JsonArgumentType.__index = JsonArgumentType
JsonArgumentType.JsonType = {
	JSON_OBJECT = "JSON_OBJECT" :: "JSON_OBJECT",
	JSON_ARRAY = "JSON_ARRAY" :: "JSON_ARRAY"
}

export type JsonType = "JSON_OBJECT"
	| "JSON_ARRAY"

export type JsonArgumentType = {
	jsonType: JsonType,
	parse: (self: JsonArgumentType, input: string) -> ({ [any]: any }, number)
}

function JsonArgumentType.new(jsonType: JsonType): JsonArgumentType
	return setmetatable({ jsonType = jsonType }, JsonArgumentType) :: JsonArgumentType
end

function JsonArgumentType.jsonObject(): JsonArgumentType
	return JsonArgumentType.new(JsonArgumentType.JsonType.JSON_OBJECT)
end

function JsonArgumentType.jsonArray(): JsonArgumentType
	return JsonArgumentType.new(JsonArgumentType.JsonType.JSON_ARRAY)
end

--

function JsonArgumentType.getJson<S>(context: CommandContext.CommandContext<S>, name: string): { [any]: any }
	local jsonArg = context:getArgument(name)
	if type(jsonArg) ~= "table" then
		error(`Argument '{name}' results in a value of type {typeof(jsonArg)}, expected table`)
	end
	return jsonArg
end

function JsonArgumentType.parse(self: JsonArgumentType, input: string): ({ [any]: any }, number)
	if self.jsonType == JsonArgumentType.JsonType.JSON_ARRAY then
		return JsonArgumentType.parseJsonArray(input)
	else
		return JsonArgumentType.parseJsonObject(input)
	end
end

function JsonArgumentType.parseJsonObject(jsonStr: string): ({ [any]: any }, number)
	-- Find JSON object starting with {
	if jsonStr:sub(1, 1) ~= "{" then
		error("Expected JSON object starting with '{'")
	end

	local endPos = JsonArgumentType.getStrEndPos(jsonStr, "{", "}")
	if endPos == 0 then
		error("Unterminated JSON object.")
	end

	jsonStr = jsonStr:sub(1, endPos)
	jsonStr = JsonArgumentType.preprocessJson(jsonStr)
	local success, jsonData = pcall(function()
		return HttpService:JSONDecode(jsonStr)
	end)
	
	if not success then
		error("Invalid JSON: " .. jsonData)
	end
	
	return jsonData, endPos
end

function JsonArgumentType.parseJsonArray(jsonStr: string): ({ [any]: any }, number)
	if jsonStr:sub(1, 1) ~= "[" then
		error("Expected JSON array starting with '['")
	end

	local endPos = JsonArgumentType.getStrEndPos(jsonStr, "[", "]")
	if endPos == 0 then
		error("Unterminated JSON array.")
	end

	jsonStr = JsonArgumentType.preprocessJson(jsonStr)
	local success, jsonData = pcall(function()
		return HttpService:JSONDecode(jsonStr)
	end)
	
	if not success then
		error("Invalid JSON: " .. jsonData)
	end

	return jsonData, endPos
end

--

function JsonArgumentType.getStrEndPos(str: string, startChar: string, endChar: string): number
	local braceCount = 0
	local endPos = 0
	for i = 1, #str do
		local char = str:sub(i, i)
		if char == startChar then
			braceCount = braceCount + 1
		elseif char == endChar then
			braceCount = braceCount - 1
			if braceCount == 0 then
				endPos = i
				break
			end
		end
	end

	return endPos
end

function JsonArgumentType.preprocessJson(jsonStr: string): string
	-- Match 'inf' that's not already in quotes
	-- This pattern looks for 'inf' that's preceded by : or [ or , and not already quoted
	jsonStr = jsonStr:gsub('([:%[,]%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	-- Handle inf at the start of values (after colons)
	jsonStr = jsonStr:gsub('(:%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	return jsonStr
end

return JsonArgumentType