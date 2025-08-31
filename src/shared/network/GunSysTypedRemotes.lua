--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return {
	BulletHit = RE("BulletHit") :: RE<Vector3, Vector3, BasePart>,
	DropShell = RE("DropShell") :: RE<CFrame>,
	HitRegister = RE("HitRegister") :: RE<boolean>
}