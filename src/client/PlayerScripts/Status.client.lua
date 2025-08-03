--!nonstrict

local REMOTE = require(game.ReplicatedStorage.shared.network.TypedRemotes).Status
local GUI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").Frame1

-- too fucking lazy to port them.
local ScreenGuies = {
	MINOR_TRESPASSING = "MINOR_TRESPASSING",
	MAJOR_TRESPASSING = "MAJOR_TRESPASSING",
	MINOR_SUSPICIOUS = "MINOR_SUSPICIOUS",
	CRIMINAL_SUSPICIOUS = "CRIMINAL_SUSPICIOUS",
	DISGUISED = "DISGUISED",
	DANGEROUS_ITEM = "DANGEROUS_ITEM",
	ARMED = "ARMED"
}

local ScreenGuiTypePerUi = {
	[ScreenGuies.DISGUISED] = GUI.Frame.A_Disguised,
	[ScreenGuies.MINOR_TRESPASSING] = GUI.Frame.B_Trespassing,
	[ScreenGuies.MINOR_SUSPICIOUS] = GUI.Frame.C_Suspicious,
	[ScreenGuies.MAJOR_TRESPASSING] = GUI.Frame.D_TrespassingRed,
	[ScreenGuies.CRIMINAL_SUSPICIOUS] = GUI.Frame.E_SuspiciousRed,
	[ScreenGuies.DANGEROUS_ITEM] = GUI.Frame.F_DangerousItem,
	[ScreenGuies.ARMED] = GUI.Frame.G_Armed
}

local currentScreenGuies = {}

REMOTE.OnClientEvent:Connect(function(ScreenGuiTypes)
	print(ScreenGuiTypes)
	for ScreenGuiType in pairs(ScreenGuiTypes) do
		if currentScreenGuies[ScreenGuiType] then
			continue
		end

		currentScreenGuies[ScreenGuiType] = true
		local ui = ScreenGuiTypePerUi[ScreenGuiType]
		if ui then
			ui.Visible = true
		end
	end

	for ScreenGuiType in pairs(currentScreenGuies) do
		if not ScreenGuiTypes[ScreenGuiType] then
			currentScreenGuies[ScreenGuiType] = nil
			local ui = ScreenGuiTypePerUi[ScreenGuiType]
			if ui then
				ui.Visible = false
			end
		end
	end
end)