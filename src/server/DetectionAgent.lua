--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)

--[=[
	Defines an interface for a type of Agent who can detect suspicious activity.
]=]
export type DetectionAgent = {
	character: Model,
	canDetectThroughDisguises: (self: DetectionAgent) -> boolean,
	getDetectionManager: (self: DetectionAgent) -> DetectionManagement.DetectionManagement
}

return nil