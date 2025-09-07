--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DetectionPayload = require(ReplicatedStorage.shared.network.DetectionPayload)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local BASE_DETECTION_TIME = 1.25
local DECAY_RATE_PER_SEC = 0.01 / 0.045 -- ≈ 0.222 (Sec. 1(d) of Plan doc.)
local DETECTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp

-- I don't know how to implement this.
-- But we will keep this shit from now on.
local STATUS_PRIORITIES = {
	SuspiciousSounds = 1,
	Disguised = 2,
	MinorTrespassing = 3,
	MinorSuspicious = 4,
	MajorTrespassing = 5,
	CriminalSuspicious = 6,
	DeadBodies = 7,
	DangerousItems = 8,
	Armed = 9,
}

local SPEED_MULTIPLIERS = {
	DeadBodies = 2.0,
	-- Everything else defaults to 1.0
}

local detectionDataBatch: { [Player]: {DetectionPayload.DetectionData} } = {}

--[=[
	@class DetectionManagement
]=]
local DetectionManagement = {}
DetectionManagement.__index = DetectionManagement

export type DetectionManagement = typeof(setmetatable({} :: {
	agent: DetectionAgent.DetectionAgent,
	detectedEntities: { [string]: DetectionProfile },
	detectionLevels: { [string]: number },
	detectedSound: Sound
}, DetectionManagement))

export type DetectionProfile = {
	isHeard: boolean?,
	isVisible: boolean?
}

type EntityPriority = {
	entityUuid: string,
	priority: number,
	distance: number,
	status: string,
	speedMultiplier: number
}

function DetectionManagement.new(agent: DetectionAgent.DetectionAgent): DetectionManagement
	return setmetatable({
		agent = agent,
		detectedEntities = {},
		detectionLevels = {},
		detectedSound = DetectionManagement.createDetectedSound(agent)
	}, DetectionManagement)
end

-- big brother be watchin you
-- "deprecated"
-- big brother can suck myy toes
-- hes my fatha
function DetectionManagement.addOrUpdateDetectedEntities(
	self: DetectionManagement, entities: { [string]: DetectionProfile }
): ()
	local newDetected: { [string]: true } = {}
	for entityUuid, detectionProfile in pairs(entities) do
		newDetected[entityUuid] = true
		self.detectedEntities[entityUuid] = detectionProfile
	end

	for uuid in pairs(self.detectedEntities) do
		if not newDetected[uuid] then
			self.detectedEntities[uuid] = nil
		end
	end
end

function DetectionManagement.getEntityPriorityInfo(
	self: DetectionManagement, entityUuid: string, detectionProfile: DetectionProfile
): EntityPriority?
	
	local entityObject = EntityManager.getEntityByUuid(entityUuid)
	if not entityObject then return nil end

	local status: string
	local entityPos: Vector3
	if entityObject.isStatic then
		entityPos = entityObject.position
	elseif entityObject.name == "Player" then
		entityPos = (entityObject.instance :: any).Character.PrimaryPart.Position -- stfu
	else
		entityPos = (entityObject.instance :: BasePart).Position
	end
	local distance = (self.agent:getPrimaryPart().Position :: Vector3 - entityPos).Magnitude

	-- This is is not even extendable.
	-- And there will be a shitton of detectable entities in the finished demo.
	-- I am not doing that shit.
	if entityObject.name == "Player" then
		entityObject = entityObject :: EntityManager.DynamicEntity
		-- Players are unique as they have statuses that determines their detection criterias.
		-- Defined in Section 1(h), this shit already handles the highest priority status
		-- that is detectable if the Player is visible and audible.
		local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(entityObject.instance :: Player)
		local highestDetectableStatus = playerStatusHolder:getHighestDetectableStatus(
			detectionProfile.isVisible or false, detectionProfile.isHeard or false
		)
		
		if not highestDetectableStatus then return nil end
		status = highestDetectableStatus.name
	elseif entityObject.name == "DeadBody" then
		status = "DeadBodies"
	elseif entityObject.name == "C4" then
		status = "DangerousItems"
	else
		return nil
	end

	-- This handles both priority and detection speed multiplier.
	-- Defined in Section 1(a) and (c) of the Plan document.
	-- Since Player statuses are their own thing, we get the priority
	-- and the detection speed multiplier from these methods.
	local priority: number
	local playerStatus = PlayerStatusTypes.getStatusFromName(status)
	if playerStatus then
		priority = playerStatus:getPriorityLevel()
	else
		priority = STATUS_PRIORITIES[status] or 0
	end
	local speedMultiplier: number
	if playerStatus then
		speedMultiplier = playerStatus:getDetectionSpeedModifier()
	else
		speedMultiplier = SPEED_MULTIPLIERS[status] or 1.0
	end
	
	return {
		entityUuid = entityUuid,
		priority = priority,
		distance = distance,
		status = status,
		speedMultiplier = speedMultiplier
	}
end

function DetectionManagement.findHighestPriorityEntity(
	self: DetectionManagement
): EntityPriority?
	
	local highestPriority: EntityPriority? = nil
	
	for entityUuid, detectionProfile in pairs(self.detectedEntities) do
		local entityInfo = self:getEntityPriorityInfo(entityUuid, detectionProfile)
		
		if entityInfo then
			if not highestPriority then
				highestPriority = entityInfo
			elseif entityInfo.priority > highestPriority.priority then
				highestPriority = entityInfo
			elseif entityInfo.priority == highestPriority.priority and entityInfo.distance < highestPriority.distance then
				highestPriority = entityInfo
			end
		end
	end

	return highestPriority
end

function DetectionManagement.update(self: DetectionManagement, deltaTime: number): ()
	local focusTarget = self:findHighestPriorityEntity()

	for entityUuid, detectionProfile in pairs(self.detectedEntities) do
		if focusTarget and entityUuid == focusTarget.entityUuid then
			self:raiseDetection(entityUuid, deltaTime, focusTarget.speedMultiplier)
		else
			self:lowerDetection(entityUuid, deltaTime)
		end
	end

	for entityUuid, _ in pairs(self.detectionLevels) do
		if not self.detectedEntities[entityUuid] then
			self:lowerDetection(entityUuid, deltaTime)
		end
	end

	--print(self.detectionLevels)
end

function DetectionManagement.raiseDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number, speedMultiplier: number
): ()
	
	local entityDetVal = self.detectionLevels[entityUuid] or 0
	if entityDetVal >= 1 then
		return
	end

	local detectionSpeed = speedMultiplier
	local progressRate = (1 / BASE_DETECTION_TIME) * detectionSpeed

	entityDetVal = math.clamp(entityDetVal + progressRate * deltaTime, 0.0, 1.0)
	self.detectionLevels[entityUuid] = entityDetVal
	self:syncDetectionToClientIfPlayer(entityUuid)
	if entityDetVal >= 1 then
		self.detectedSound:Play()
	end
end

function DetectionManagement.lowerDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number
): ()
	local level = self.detectionLevels[entityUuid]
	if not level then
		return
	end

	if level >= 1 then return end
	
	local finalDet = math.max(0, level - DECAY_RATE_PER_SEC * deltaTime)
	if finalDet > 0 then
		self.detectionLevels[entityUuid] = finalDet
	else
		self.detectionLevels[entityUuid] = nil
	end
	self:syncDetectionToClientIfPlayer(entityUuid)
end

function DetectionManagement.syncDetectionToClientIfPlayer(
	self: DetectionManagement, entityUuid: string
): ()
	local entity = EntityManager.getEntityByUuid(entityUuid)
	if not entity then return end

	if entity.name == "Player" then
		entity = entity :: EntityManager.DynamicEntity
		DetectionManagement.addToBatch(entity.instance :: Player, {
			character = self.agent.character,
			uuid = (self.agent :: any):getUuid() :: string,
			detectionValue = self.detectionLevels[entityUuid] or 0
		})
	end
end

function DetectionManagement.addToBatch(to: Player, data: DetectionPayload.DetectionData)
	if not detectionDataBatch[to] then
		detectionDataBatch[to] = {}
	end

	table.insert(detectionDataBatch[to], data)
end

function DetectionManagement.flushBatchToClients(): ()
	for player, datas in pairs(detectionDataBatch) do
		TypedRemotes.Detection:FireClient(player, datas)
	end

	table.clear(detectionDataBatch)
end

--

function DetectionManagement.createDetectedSound(agent: DetectionAgent.DetectionAgent): Sound
	local newSound = DETECTED_SOUND:Clone()
	newSound.Parent = agent:getPrimaryPart()
	return newSound
end

return DetectionManagement