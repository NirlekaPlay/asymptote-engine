--!nonstrict

local REMOTE = require(game.ReplicatedStorage.shared.network.TypedRemotes).Status
local GUI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").Frame1

-- too fucking lazy to port them.
local PlayerStatus = {
	MINOR_TRESPASSING = "MINOR_TRESPASSING",
	MAJOR_TRESPASSING = "MAJOR_TRESPASSING",
	MINOR_SUSPICIOUS = "MINOR_SUSPICIOUS",
	CRIMINAL_SUSPICIOUS = "CRIMINAL_SUSPICIOUS",
	DISGUISED = "DISGUISED",
	DANGEROUS_ITEM = "DANGEROUS_ITEM",
	ARMED = "ARMED"
}

local ScreenGuiTypePerUi = {
	[PlayerStatus.DISGUISED] = GUI.Frame.A_Disguised,
	[PlayerStatus.MINOR_TRESPASSING] = GUI.Frame.B_Trespassing,
	[PlayerStatus.MINOR_SUSPICIOUS] = GUI.Frame.C_Suspicious,
	[PlayerStatus.MAJOR_TRESPASSING] = GUI.Frame.D_TrespassingRed,
	[PlayerStatus.CRIMINAL_SUSPICIOUS] = GUI.Frame.E_SuspiciousRed,
	[PlayerStatus.DANGEROUS_ITEM] = GUI.Frame.F_DangerousItem,
	[PlayerStatus.ARMED] = GUI.Frame.G_Armed
}

local currentPlayerStatus = {}

REMOTE.OnClientEvent:Connect(function(playerStatusesMap)
	for ScreenGuiType in pairs(playerStatusesMap) do
		if currentPlayerStatus[ScreenGuiType] then
			continue
		end

		currentPlayerStatus[ScreenGuiType] = true
		local ui = ScreenGuiTypePerUi[ScreenGuiType]
		if ui then
			ui.Visible = true
		end
	end

	for ScreenGuiType in pairs(currentPlayerStatus) do
		if not playerStatusesMap[ScreenGuiType] then
			currentPlayerStatus[ScreenGuiType] = nil
			local ui = ScreenGuiTypePerUi[ScreenGuiType]
			if ui then
				ui.Visible = false
			end
		end
	end
end)