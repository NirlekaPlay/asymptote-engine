--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)

local HalfAssedSuggestionsTests = {}

local dispatcher = CommandDispatcher.new()
dispatcher:register(
	CommandHelper.literal("verylongcommand")
		:andThen(
			CommandHelper.literal("secondargument")
				:executes(function(c)
					return 1
				end)
		)
)

local parsed = dispatcher:parseString("verylong", {})
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
local list = suggestions:getList()

local found = false
for _, suggestion in list do
	if suggestion:getText() == "verylongcommand" then
		found = true
		break
	end
end

assert(found, "Should have suggested 'verylongcommand'")
print("✅ Suggestions test passed!")

return HalfAssedSuggestionsTests