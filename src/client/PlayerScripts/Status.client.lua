local REMOTE = require(game.ReplicatedStorage.shared.network.TypedStatusRemote)

-- too fucking lazy to port them.
local Statuses = {
	MINOR_TRESPASSING = "MINOR_TRESPASSING",
	MAJOR_TRESPASSING = "MAJOR_TRESPASSING",
	MINOR_SUSPICIOUS = "MINOR_SUSPICIOUS",
	CRIMINAL_SUSPICIOUS = "CRIMINAL_SUSPICIOUS",
	DISGUISED = "DISGUISED",
	ARMED = "ARMED"
}

local StatusTypePerUi = {
	[Statuses.MINOR_TRESPASSING] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").A_Trespassing,
	[Statuses.MAJOR_TRESPASSING] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").B_TrespassingRed,
	[Statuses.ARMED] = game.Players.LocalPlayer.PlayerGui:WaitForChild("Status").C_Armed
}

REMOTE.OnClientEvent:Connect(function(statusType, bool)
	local ui = StatusTypePerUi[statusType]
	if ui then
		ui.Visible = bool
		if bool then
			ui.Parent = game.Players.LocalPlayer.PlayerGui.Status.SafeArea.Bar
		else
			ui.Parent = game.Players.LocalPlayer.PlayerGui.Status
		end
	end
end)