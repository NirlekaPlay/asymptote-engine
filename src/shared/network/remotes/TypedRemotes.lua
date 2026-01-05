--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlertLevels = require(ReplicatedStorage.shared.alertlevel.AlertLevels)
local BrainDebugPayload = require(ReplicatedStorage.shared.network.payloads.BrainDebugPayload)
local CharacterAppearancePayload = require(ReplicatedStorage.shared.network.payloads.CharacterAppearancePayload)
local ClientBoundChatMessagePayload = require(ReplicatedStorage.shared.network.payloads.ClientBoundChatMessagePayload)
local ClientBoundDialogueConceptsPayload = require(ReplicatedStorage.shared.network.payloads.ClientBoundDialogueConceptsPayload)
local ClientBoundObjectivesInfoPayload = require(ReplicatedStorage.shared.network.payloads.ClientBoundObjectivesInfoPayload)
local DetectionPayload = require(ReplicatedStorage.shared.network.payloads.DetectionPayload)
local LocalTweenPayload = require(ReplicatedStorage.shared.network.payloads.LocalTweenPayload)
local CameraSocket = require(ReplicatedStorage.shared.player.level.camera.CameraSocket)
local TypedRemote = require(ReplicatedStorage.shared.thirdparty.TypedRemote)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)

local _, RE = TypedRemote.parent()

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

local playerHeadRotationJointRemote = RE("PlayerHeadRotation")
return {
	Detection = RE("Detection") :: RE<{DetectionPayload.DetectionData}>,
	BubbleChat = RE("BubbleChat") :: RE<BasePart, string?>,
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
	ClientBoundDynamicDebugDump = RE("ClientBoundDynamicDebugDump") :: RE<string, any>,
	--
	ClientBoundChatMessage = RE("ClientBoundChatMessage") :: RE<ClientBoundChatMessagePayload.ClientBoundChatMessagePayload>,
	--
	ServerBoundGlobalStatesReplicateRequest = RE("ServerBoundGlobalStatesReplicateRequest") :: RE<>,
	ClientBoundReplicateIndividualGlobalStates = RE("ClientBoundReplicateGlobalStates") :: RE<string, any>,
	ClientBoundReplicateAllGlobalStates = RE("ClientBoundReplicateAllGlobalStates") :: RE<{[string]:any}>,
	--
	ClientBoundLocalizationAppend = RE("ClientBoundLocalizationAppend") :: RE<{[string]:string}>,
	--
	ClientBoundCharacterAppearances = RE("ClientBoundCharacterAppearance") :: RE<{CharacterAppearancePayload.CharacterAppearancePayload}>,
	--
	ClientBoundObjectivesInfo = RE("ClientBoundObjectivesInfo") :: RE<ClientBoundObjectivesInfoPayload.ObjectivesInfoPayload>,
	ClientBoundMissionConcluded = RE("ClientBoundMissionConcluded") :: RE<CameraSocket.CameraSocket, boolean>,
	ClientBoundMissionStart = RE("ClientBoundMissionStart") :: RE<>,
	--
	ClientBoundTeleportReady = RE("ClientBoundTeleportReady"),
	ServerBoundPlayerTeleportReady = RE("ServerBoundPlayerTeleportReady"),
	ServerBoundPlayerWantRestart = RE("ServerBoundPlayerWantRestart"),
	ClientBoundRemainingRestartPlayers = RE("ClientBoundRemainingRestartPlayers") :: RE<number, number>,
	ClientBoundServerMatchInfo = RE("ClientBoundServerMatchInfo") :: RE<string, { isConcluded: boolean, isFailed: boolean, cameraSocket: CameraSocket.CameraSocket}>,
	--
	ClientBoundTween = RE("ClientBoundTween") :: RE<LocalTweenPayload.LocalTweenPayload>,
	--
	ClientBoundForeignChatMessage = RE("ClientBoundForeign") :: RE<Player, string>,
	ServerBoundClientForeignChatted = RE("ServerBoundForeign") :: RE<string>,
	--
	ClientBoundDialogueConceptEvaluate = RE("ClientBoundDialogueConceptEvaluate") :: RE<string, {[string]:any}>,
	ClientBoundRegisterDialogueConcepts = RE("ClientBoundRegisterConcepts") :: RE<ClientBoundDialogueConceptsPayload.ClientBoundDialogueConceptsPayload>
}