--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return {
	Detection = RE("Detection") :: RE<number, Model, Vector3>,
	BubbleChat = RE("BubbleChat") :: RE<BasePart, string>,
	Status = RE("Status") :: RE<{ [any]: true }>
}