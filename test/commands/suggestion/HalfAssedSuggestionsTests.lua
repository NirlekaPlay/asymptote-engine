--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local Commands = require(ServerScriptService.server.commands.registry.Commands)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)

local HalfAssedSuggestionsTests = {}

local dispatcher = Commands.getDispatcher()

task.wait(3)

--[[CommandDispatcher.new()
dispatcher:register(
	CommandHelper.literal("verylongcommand")
		:andThen(
			CommandHelper.literal("secondargument")
				:executes(function(c)
					return 1
				end)
		)
)]]

local parsed = dispatcher:parseString("var", {})
local future = dispatcher:getCompletionSuggestions(parsed)
local timeout = 5
local start = os.clock()
while not future:isDone() do
	if os.clock() - start > timeout then
		error("Suggestions timed out!")
	end
	task.wait() -- Yield to allow task.spawned callbacks to run
end

-- 2. Join the result
local suggestions = future:join()

-- 3. Assertions
-- Assuming your Suggestions object has a getList() or similar method
local list = suggestions and suggestions:getList() or nil

assert(list, "Didn't find anything")
print("✅ Suggestions test passed!")
print(list)

return HalfAssedSuggestionsTests