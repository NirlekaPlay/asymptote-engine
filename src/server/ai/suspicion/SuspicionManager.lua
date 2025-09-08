--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DetectionPayload = require(ReplicatedStorage.shared.network.payloads.DetectionPayload)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local BrainOwner = require(ServerScriptService.server.BrainOwner)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.remotes.TypedRemotes).Detection
local CONFIG = {
	BASE_DETECTION_TIME = 1.25,        -- The base amount of time (in seconds) the detection goes from 0.0 to 1.0
	QUICK_DETECTION_RANGE = 10,        -- In studs
	QUICK_DETECTION_MULTIPLIER = 3.33, -- If a suspect is within QUICK_DETECTION_RANGE, the detection speed is multiplied by this
	DECAY_RATE_PER_SECOND = 0.2222,    -- Equivalent to 1% per 0.045s
	CURIOUS_THRESHOLD = 60 / 100,      -- 60% progress to trigger curious state
	CURIOUS_COOLDOWN_TIME = 2,         -- In seconds,
	INSTANT_DETECTION_RULES = {
		[PlayerStatusTypes.ARMED] = 20,                    -- Pulling out a gun triggers instant detection within this distance
		[PlayerStatusTypes.DANGEROUS_ITEM] = 12.5          -- Carrying C4 triggers instant detection within this distance
	},
	QUICK_DETECTION_INSTANT_STATUSES = { -- Suspects with this status within the QUICK_DETECTION_RANGE will be instantly detected
		[PlayerStatusTypes.ARMED] = true
	},
	ALERTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp
}

local detectionDataBatch: { [Player]: {DetectionPayload.DetectionData} } = {}
local statusTracker: { [Player]: PlayerStatus.PlayerStatus } = {}

local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement

export type SuspicionManagement = typeof(setmetatable({} :: {
	agent: DetectionAgent.DetectionAgent & BrainOwner.BrainOwner,
	focusingOn: Player?,
	suspicionLevels: { [EntityManager.Entity]: { [PlayerStatus.PlayerStatus]: number } },
	detectedStatuses: { [PlayerStatus.PlayerStatus]: Player },
	curiousState: boolean,
	curiousCooldown: number
}, SuspicionManagement))