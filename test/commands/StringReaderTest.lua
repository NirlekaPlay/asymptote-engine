--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)

local StringReaderTest = {}

function StringReaderTest.testCanRead(): ()
	local reader = StringReader.fromString("abc")
	assert(reader:canRead() == true)
	reader:skip() -- 'a'
	assert(reader:canRead() == true)
	reader:skip() -- 'b'
	assert(reader:canRead() == true)
	reader:skip() -- 'c'
	assert(reader:canRead() == false)
end

function StringReaderTest.testGetRemainingLength(): ()
	local reader = StringReader.fromString("abc")
	assert(reader:getRemainingLength() == 3)
	reader:setCursorPos(1)
	assert(reader:getRemainingLength() == 2)
	reader:setCursorPos(2)
	assert(reader:getRemainingLength() == 1)
	reader:setCursorPos(3)
	assert(reader:getRemainingLength() == 0)
end

return StringReaderTest