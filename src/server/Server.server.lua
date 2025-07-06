local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SuspicionManagement = require(ServerScriptService.Server.ai.suspicion.SuspicionManagement)

local currentSusMan = SuspicionManagement.new()

RunService.PreAnimation:Connect(function()
	currentSusMan:update()
end)