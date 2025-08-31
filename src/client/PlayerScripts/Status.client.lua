--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local REMOTE = require(game.ReplicatedStorage.shared.network.TypedRemotes).Status
local GUI = Players.LocalPlayer.PlayerGui:WaitForChild("Status").Frame1

local playerStatusesPerUi = {
	[PlayerStatusTypes.DISGUISED.name] = GUI.Frame.A_Disguised,
	[PlayerStatusTypes.MINOR_TRESPASSING.name] = GUI.Frame.B_Trespassing,
	[PlayerStatusTypes.MINOR_SUSPICIOUS.name] = GUI.Frame.C_Suspicious,
	[PlayerStatusTypes.MAJOR_TRESPASSING.name] = GUI.Frame.D_TrespassingRed,
	[PlayerStatusTypes.CRIMINAL_SUSPICIOUS.name] = GUI.Frame.E_SuspiciousRed,
	[PlayerStatusTypes.DANGEROUS_ITEM.name] = GUI.Frame.F_DangerousItem,
	[PlayerStatusTypes.ARMED.name] = GUI.Frame.G_Armed
}

local currentPlayerStatusTypes: { [string]: true } = {}

REMOTE.OnClientEvent:Connect(function(playerStatusesMap)
	for playerStatus in pairs(playerStatusesMap) do
		if currentPlayerStatusTypes[playerStatus] then
			continue
		end

		currentPlayerStatusTypes[playerStatus] = true
		local ui = playerStatusesPerUi[playerStatus]
		if ui then
			ui.Visible = true
		end
	end

	for playerStatus in pairs(currentPlayerStatusTypes) do
		if not playerStatusesMap[playerStatus] then
			currentPlayerStatusTypes[playerStatus] = nil
			local ui = playerStatusesPerUi[playerStatus]
			if ui then
				ui.Visible = false
			end
		end
	end
end)