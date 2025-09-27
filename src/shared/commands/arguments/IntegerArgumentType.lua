--!strict

local IntegerArgumentType = {}

function IntegerArgumentType.parse(input: string): (any, number)
	local num = tonumber(input:match("^%-?%d+"))
	if num then
		local len = tostring(math.floor(num)):len()
		if input:sub(1, 1) == "-" then len += 1 end
		return num, len
	end
	error("Expected integer, got: " .. input)
end

return IntegerArgumentType