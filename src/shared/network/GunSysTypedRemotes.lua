--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BulletTracerPayload = require(script.Parent.BulletTracerPayload)
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return {
	BulletTracer = RE("BulletTracer") :: RE<BulletTracerPayload.BulletTracer>,
	DropShell = RE("DropShell") :: RE<CFrame>,
	HitRegister = RE("HitRegister") :: RE<boolean>
}