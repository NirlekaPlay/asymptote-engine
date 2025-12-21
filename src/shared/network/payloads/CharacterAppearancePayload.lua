--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BodyColorType = require(ReplicatedStorage.shared.network.types.BodyColorType)

export type CharacterAppearancePayload = {
	character: Model,
	bodyColors: BodyColorType.BodyColorType
}

return nil