--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local DeanHaunt = require(StarterPlayer.StarterPlayerScripts.client.modules.character.DeanHaunt)
local IsHalloween = require(StarterPlayer.StarterPlayerScripts.client.modules.util.IsHalloween)

local CHECK_INTERVAL = 60

local function updateHalloweenState()
	local isHalloween = IsHalloween()
	
	if isHalloween and not DeanHaunt.isRunning() then
		DeanHaunt.initialize()
		print("🎃 Halloween mode activated")
	elseif not isHalloween and DeanHaunt.isRunning() then
		DeanHaunt.stop()
		print("👻 Halloween mode deactivated")
	end
end

updateHalloweenState()

task.spawn(function()
	while true do
		task.wait(CHECK_INTERVAL)
		updateHalloweenState()
	end
end)