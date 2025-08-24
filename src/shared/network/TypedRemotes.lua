--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainDebugPayload = require(script.Parent.BrainDebugPayload)
local DetectionPayload = require(script.Parent.DetectionPayload)
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

local playerHeadRotationJointRemote = RE("PlayerHeadRotation")
return {
	Detection = RE("Detection") :: RE<{DetectionPayload.DetectionData}>,
	BubbleChat = RE("BubbleChat") :: RE<BasePart, string>,
	Status = RE("Status") :: RE<{ [any]: true }>,
	--
	PlayerHeadRotationServer = playerHeadRotationJointRemote :: RE<Vector3>,
	PlayerHeadRotationClient = playerHeadRotationJointRemote :: RE<Player, Vector3>,
	--
	JoinTestingServer = RE("JoinTestingServer") :: RE<>,
	JoinStableServer = RE("JoinStableServer") :: RE<>,
	--
	BrainDebugDump = RE("BrainDebugDump") :: RE<{BrainDebugPayload.BrainDump}>,
	SubscribeDebugDump = RE("SubscribeDebugDump") :: RE<string, boolean>
}