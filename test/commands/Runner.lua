--!strict

local TestService = game:GetService("TestService")
local CommandDispatcherTest = require(TestService.commands.CommandDispatcherTest)

local test0 = CommandDispatcherTest.setUp()
test0:testDispatcherType()

return nil