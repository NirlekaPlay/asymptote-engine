--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

--[=[
	@class HeadsUpNotificationService
]=]
local HeadsUpNotificationService = {}

function HeadsUpNotificationService.notifyAllPlayers(localizedStr: string): ()
	TypedRemotes.ClientboundHeadsUpNotif:FireAllClients(localizedStr)
end

return HeadsUpNotificationService