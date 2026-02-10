--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DaytimeLightingConfig = require(ServerScriptService.server.world.lighting.configs.DaytimeLightingConfig)
local DennisLightingConfig = require(ServerScriptService.server.world.lighting.configs.DennisLightingConfig)
local SpookyLightingConfig = require(ServerScriptService.server.world.lighting.configs.SpookyLightingConfig)
local WinterLightingConfig = require(ServerScriptService.server.world.lighting.configs.WinterLightingConfig)

return {
	DAYTIME = DaytimeLightingConfig,
	SPOOKY = SpookyLightingConfig,
	WINTER = WinterLightingConfig,
	DENNIS = DennisLightingConfig
}