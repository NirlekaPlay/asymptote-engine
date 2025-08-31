--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlertLevels = require(ReplicatedStorage.shared.alert_level.AlertLevels)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)

local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer.PlayerGui
local statusUi = localPlayerGui:WaitForChild("Status")

local UI_PER_ALERT_LEVELS = {
	[AlertLevels.CALM] = statusUi.Frame1.Frame.A_AlertLevel_Calm,
	[AlertLevels.NORMAL] = statusUi.Frame1.Frame.A_AlertLevel_Normal,
	[AlertLevels.ALERT] = statusUi.Frame1.Frame.A_AlertLevel_Alert,
	[AlertLevels.SEARCHING] = statusUi.Frame1.Frame.A_AlertLevel_Searching,
	[AlertLevels.LOCKDOWN] = statusUi.Frame1.Frame.A_AlertLevel_Lockdown
}

TypedRemotes.AlertLevel.OnClientEvent:Connect(function(alertLevel)
	for respectedAlertLevel, ui in pairs(UI_PER_ALERT_LEVELS) do
		if respectedAlertLevel.name == alertLevel.name then
			ui.Visible = true
		else
			ui.Visible = false
		end
	end
end)
