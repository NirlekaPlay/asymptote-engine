--!nonstrict

local REMOTE = require(game.ReplicatedStorage.shared.network.TypedStatusRemote)

-- too fucking lazy to port them.
local Statuses = {
	MINOR_TRESPASSING = "MINOR_TRESPASSING",
	MAJOR_TRESPASSING = "MAJOR_TRESPASSING",
	MINOR_SUSPICIOUS = "MINOR_SUSPICIOUS",
	CRIMINAL_SUSPICIOUS = "CRIMINAL_SUSPICIOUS",
	DISGUISED = "DISGUISED",
	DANGEROUS_ITEM = "DANGEROUS_ITEM",
	ARMED = "ARMED"
}

local StatusTypePerUi = {
	[Statuses.DISGUISED] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").A_Disguised,
	[Statuses.MINOR_TRESPASSING] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").B_Trespassing,
	[Statuses.MINOR_SUSPICIOUS] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").C_Suspicious,
	[Statuses.MAJOR_TRESPASSING] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").D_TrespassingRed,
	[Statuses.CRIMINAL_SUSPICIOUS] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").E_SuspiciousRed,
	[Statuses.DANGEROUS_ITEM] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").F_DangerousItem,
	[Statuses.ARMED] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").G_Armed
}

local currentStatuses = {}

REMOTE.OnClientEvent:Connect(function(statusTypes)
	for statusType in pairs(statusTypes) do
		if currentStatuses[statusType] then
			continue
		end

		currentStatuses[statusType] = true
		local ui = StatusTypePerUi[statusType]
		if ui then
			ui.Visible = true
			ui.Parent = game.Players.LocalPlayer.PlayerGui.Status.SafeArea.Bar
		end
	end

	for statusType in pairs(currentStatuses) do
		if not statusTypes[statusType] then
			currentStatuses[statusType] = nil
			local ui = StatusTypePerUi[statusType]
			if ui then
				ui.Visible = false
				ui.Parent = game.Players.LocalPlayer.PlayerGui.Status
			end
		end
	end
end)