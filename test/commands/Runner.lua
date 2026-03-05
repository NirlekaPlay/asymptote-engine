--!strict

local TestService = game:GetService("TestService")
local CommandDispatcherTest = require(TestService.commands.CommandDispatcherTest)

local function runTests(obj: any)
	if not obj.setUp or type(obj.setUp) ~= "function" then
		error("Test class must have a setUp method")
	end
	for key, value in pairs(obj) do
		local isFunction = type(value) == "function"
		local isNotInternal = key:sub(1, 1) ~= "_"
		local isNotSetUp = key ~= "setUp"
		if isFunction and isNotSetUp and isNotInternal then
			local inst = obj:setUp()
			local success, err = pcall(function()
				value(inst)
			end)
			if success then
				print("Test passed:", key)
			else
				warn("Test failed:", key, "Error:", err)
			end
		end
	end
end

runTests(CommandDispatcherTest)

return nil