--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local isStudio = RunService:IsStudio()

local PLACE_IDS = {
	SECONDARY_TESTING_SERVER = 139078384856437,
	TESTING_SERVER = 113936939292070,
	STABLE_SERVER = 111847508391227
}

local function warnTeleportSuccessInStudioEnvironment(player: Player, destinationPlaceId: number): ()
	warn("Studio environment detected while teleporting.")
	warn(`Teleport request has been received from player '{player.Name}' to destination of {destinationPlaceId}`)
end

TypedRemotes.JoinStableServer.OnServerEvent:Connect(function(player)
	if isStudio then
		warnTeleportSuccessInStudioEnvironment(player, PLACE_IDS.STABLE_SERVER)
		return
	end
	TeleportService:TeleportAsync(PLACE_IDS.STABLE_SERVER, {player})
end)

TypedRemotes.JoinTestingServer.OnServerEvent:Connect(function(player)
	if isStudio then
		warnTeleportSuccessInStudioEnvironment(player, PLACE_IDS.SECONDARY_TESTING_SERVER)
		return
	end
	TeleportService:TeleportAsync(PLACE_IDS.SECONDARY_TESTING_SERVER, {player})
end)