--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)

export type Config = {
	canBeTrespassed: boolean,
	penalties: {
		disguised: PlayerStatus.PlayerStatus?,
		undisguised: PlayerStatus.PlayerStatus?
	}
}

return nil