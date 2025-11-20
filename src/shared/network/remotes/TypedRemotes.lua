--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlertLevels = require(ReplicatedStorage.shared.alertlevel.AlertLevels)
local BrainDebugPayload = require(ReplicatedStorage.shared.network.payloads.BrainDebugPayload)
local ClientBoundChatMessagePayload = require(ReplicatedStorage.shared.network.payloads.ClientBoundChatMessagePayload)
local DetectionPayload = require(ReplicatedStorage.shared.network.payloads.DetectionPayload)
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

local playerHeadRotationJointRemote = RE("PlayerHeadRotation")
return {
	Detection = RE("Detection") :: RE<{DetectionPayload.DetectionData}>,
	BubbleChat = RE("BubbleChat") :: RE<BasePart, string>,
	Status = RE("Status") :: RE<{ [string]: true }>,
	AlertLevel = RE("AlertLevel") :: RE<AlertLevels.AlertLevel>,
	--
	PlayerHeadRotationServer = playerHeadRotationJointRemote :: RE<Vector3>,
	PlayerHeadRotationClient = playerHeadRotationJointRemote :: RE<Player, Vector3>,
	--
	JoinTestingServer = RE("JoinTestingServer") :: RE<>,
	JoinStableServer = RE("JoinStableServer") :: RE<>,
	--
	BrainDebugDump = RE("BrainDebugDump") :: RE<{BrainDebugPayload.BrainDump}>,
	SubscribeDebugDump = RE("SubscribeDebugDump") :: RE<string, boolean>,
	--
	ClientBoundChatMessage = RE("ClientBoundChatMessage") :: RE<ClientBoundChatMessagePayload.ClientBoundChatMessagePayload>,
	--
	ServerBoundGlobalStatesReplicateRequest = RE("ClientBoundChatMessage") :: RE<>,
	ClientBoundReplicateIndividualGlobalStates = RE("ClientBoundReplicateGlobalStates") :: RE<string, any>,
	ClientBoundReplicateAllGlobalStates = RE("ClientBoundReplicateAllGlobalStates") :: RE<{[string]:any}>
}