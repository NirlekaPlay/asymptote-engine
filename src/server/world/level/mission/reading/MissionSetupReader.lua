--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local MissionSetupReaderV1 = require(ServerScriptService.server.world.level.mission.reading.readers.MissionSetupReaderV1)

--[=[
	@class MissionSetupReader
]=]
local MissionSetupReader = {}

function MissionSetupReader.read(module: ModuleScript): MissionSetup.MissionSetup
	return MissionSetupReaderV1.parse(module)
end

return MissionSetupReader