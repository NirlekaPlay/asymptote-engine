--!strict

local HttpService = game:GetService("HttpService")

local JsonArgumentType = {}

function JsonArgumentType.parse(input: string): (any, number)
	-- Find JSON object starting with {
	if input:sub(1, 1) ~= "{" then
		error("Expected JSON object starting with '{'")
	end
	
	-- Simple bracket matching to find end of JSON
	local braceCount = 0
	local endPos = 0
	for i = 1, #input do
		local char = input:sub(i, i)
		if char == "{" then
			braceCount = braceCount + 1
		elseif char == "}" then
			braceCount = braceCount - 1
			if braceCount == 0 then
				endPos = i
				break
			end
		end
	end
	
	if endPos == 0 then
		error("Unterminated JSON object")
	end
	
	local jsonStr = input:sub(1, endPos)
	jsonStr = JsonArgumentType.preprocessJSON(jsonStr)
	local success, jsonData = pcall(function()
		return HttpService:JSONDecode(jsonStr)
	end)
	
	if not success then
		error("Invalid JSON: " .. jsonData)
	end
	
	return jsonData, endPos
end

function JsonArgumentType.preprocessJSON(jsonStr: string): string
	-- Match 'inf' that's not already in quotes
	-- This pattern looks for 'inf' that's preceded by : or [ or , and not already quoted
	jsonStr = jsonStr:gsub('([:%[,]%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	-- Handle inf at the start of values (after colons)
	jsonStr = jsonStr:gsub('(:%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	return jsonStr
end

return JsonArgumentType