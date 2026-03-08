--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BulletTracerPayload = require(ReplicatedStorage.shared.network.payloads.BulletTracerPayload)
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, _, URE = TypedRemote.parent()

type RE<T...> = TypedRemote.Event<T...>
type URE<T...> = TypedRemote.UnreliableEvent<T...>

return {
	BulletTracer = URE("BulletTracer") :: URE<BulletTracerPayload.BulletTracer>,
	DropShell = URE("DropShell") :: URE<CFrame>,
	HitRegister = URE("HitRegister") :: URE<boolean>
}