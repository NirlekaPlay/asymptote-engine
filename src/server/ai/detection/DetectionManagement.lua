--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local DetectionPayload = require(ReplicatedStorage.shared.network.DetectionPayload)

local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local BASE_DETECTION_TIME = 1.25
local QUICK_DETECTION_RANGE = 10
local QUIK_DETECTION_MULTIPLIER = 3.33
local DECAY_RATE_PER_SEC = 0.01 / 0.045 -- ≈ 0.222 (Sec. 1(d) of Plan doc.)
local INSTANT_DETECTION_RULES = {
	[PlayerStatusTypes.ARMED] = 20,             -- Pulling out a gun triggers instant detection within this distance
	[PlayerStatusTypes.DANGEROUS_ITEM] = 12.5   -- Carrying C4 triggers instant detection within this distance
}
local QUICK_DETECTION_INSTANT_STATUSES = {      -- Suspects with this status within the QUICK_DETECTION_RANGE will be instantly detected
	[PlayerStatusTypes.ARMED] = true
}
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
local playerStatusTracker: { [Player]: PlayerStatus.PlayerStatus } = {}

--[=[
	@class DetectionManagement
]=]
local DetectionManagement = {}
DetectionManagement.__index = DetectionManagement

export type DetectionManagement = typeof(setmetatable({} :: {
	agent: Agent,
	detectedEntities: { [string]: DetectionProfile },
	detectionLevels: { [string]: number },
	detectedSound: Sound
}, DetectionManagement))

export type DetectionProfile = {
	isHeard: boolean?,
	isVisible: boolean?
}

type Agent = Agent.Agent

type EntityPriority = {
	entityUuid: string,
	priority: number,
	distance: number,
	status: string,
	speedMultiplier: number
}

function DetectionManagement.new(agent: Agent): DetectionManagement
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
	self: DetectionManagement,
	entityUuid: string,
	detectionProfile: DetectionProfile
): { EntityPriority }
	local results = {}

	local entityObject = EntityManager.getEntityByUuid(entityUuid)
	if not entityObject then
		return results
	end

	local entityPos
	if entityObject.isStatic then
		entityPos = entityObject.position
	elseif entityObject.name == "Player" then
		entityPos = (entityObject.instance :: any).Character.PrimaryPart.Position
	else
		entityPos = (entityObject.instance :: BasePart).Position
	end
	local distance = (self.agent:getPrimaryPart().Position - entityPos).Magnitude

	if entityObject.name == "Player" then
		entityObject = entityObject :: EntityManager.DynamicEntity
		local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(entityObject.instance :: Player)

		local statuses: { PlayerStatus.PlayerStatus }
		local highestDetectableStatus = playerStatusHolder:getHighestDetectableStatus(
			detectionProfile.isVisible or false,
			detectionProfile.isHeard or false
		)
		if highestDetectableStatus then
			statuses = { highestDetectableStatus }
		else
			statuses = {}
		end

		for _, status in ipairs(statuses) do
			local statusName = status.name
			local playerStatus = PlayerStatusTypes.getStatusFromName(statusName)
			local priority = playerStatus and playerStatus:getPriorityLevel() or STATUS_PRIORITIES[statusName] or 0
			local speedMultiplier = playerStatus and playerStatus:getDetectionSpeedModifier() or SPEED_MULTIPLIERS[statusName] or 1.0

			table.insert(results, {
				entityUuid = entityUuid,
				status = statusName,
				priority = priority,
				distance = distance,
				speedMultiplier = speedMultiplier
			})
		end

	-- This shit is not even expandable.
	-- But it works so oh well.
	elseif entityObject.name == "DeadBody" then
		table.insert(results, {
			entityUuid = entityUuid,
			status = "DeadBodies",
			priority = STATUS_PRIORITIES["DeadBodies"] or 0,
			distance = distance,
			speedMultiplier = SPEED_MULTIPLIERS["DeadBodies"] or 1.0
		})
	elseif entityObject.name == "C4" then
		table.insert(results, {
			entityUuid = entityUuid,
			status = "DangerousItems",
			priority = STATUS_PRIORITIES["DangerousItems"] or 0,
			distance = distance,
			speedMultiplier = SPEED_MULTIPLIERS["DangerousItems"] or 1.0
		})
	end

	return results
end

function DetectionManagement.findHighestPriorityEntity(
	self: DetectionManagement
): EntityPriority?
	local highestPriority: EntityPriority? = nil

	for entityUuid, detectionProfile in pairs(self.detectedEntities) do
		local infos = self:getEntityPriorityInfo(entityUuid, detectionProfile)
		for _, info in ipairs(infos) do
			if not highestPriority then
				highestPriority = info
			elseif info.priority > highestPriority.priority then
				highestPriority = info
			elseif info.priority == highestPriority.priority and info.distance < highestPriority.distance then
				highestPriority = info
			end
		end
	end

	return highestPriority
end

function DetectionManagement.update(self: DetectionManagement, deltaTime: number): ()
	local focusTarget = self:findHighestPriorityEntity()
	local currentlyDetectedKeys: { [string]: true } = {}

	for entityUuid, detectionProfile in pairs(self.detectedEntities) do
		local infos = self:getEntityPriorityInfo(entityUuid, detectionProfile)

		local entity = EntityManager.getEntityByUuid(entityUuid)
		if entity and entity.name == "Player" then
			local highestPriorityInfo = nil
			for _, info in ipairs(infos) do
				if not highestPriorityInfo or info.priority > highestPriorityInfo.priority then
					highestPriorityInfo = info
				end
			end
			
			if highestPriorityInfo then
				local currentKey = entityUuid .. ":" .. highestPriorityInfo.status
				local maxDetectionForPlayer = 0
				local oldKeyToTransferFrom = nil
				
				for key, level in pairs(self.detectionLevels) do
					if string.match(key, "^" .. entityUuid .. ":") then
						if level > maxDetectionForPlayer then
							maxDetectionForPlayer = level
							if key ~= currentKey then
								oldKeyToTransferFrom = key
							end
						end
					end
				end
				
				if oldKeyToTransferFrom and maxDetectionForPlayer > 0 then
					self.detectionLevels[currentKey] = maxDetectionForPlayer
					for key, _ in pairs(self.detectionLevels) do
						if string.match(key, "^" .. entityUuid .. ":") and key ~= currentKey then
							self.detectionLevels[key] = nil
						end
					end
				end
				
				currentlyDetectedKeys[currentKey] = true

				if focusTarget
					and focusTarget.entityUuid == highestPriorityInfo.entityUuid
					and focusTarget.status == highestPriorityInfo.status
				then
					self:raiseDetection(currentKey, deltaTime, highestPriorityInfo)
				else
					self:lowerDetection(currentKey, deltaTime)
				end
			end
		else
			for _, info in ipairs(infos) do
				local key = entityUuid .. ":" .. info.status
				currentlyDetectedKeys[key] = true

				if focusTarget
					and focusTarget.entityUuid == info.entityUuid
					and focusTarget.status == info.status
				then
					self:raiseDetection(key, deltaTime, info)
				else
					self:lowerDetection(key, deltaTime)
				end
			end
		end
	end

	for key, _ in pairs(self.detectionLevels) do
		if not currentlyDetectedKeys[key] then
			local entityUuid = string.match(key, "^(.-):") :: string
			local entity = EntityManager.getEntityByUuid(entityUuid)
			
			if entity and entity.name == "Player" then
				local hasCurrentDetection = false
				for currentKey, _ in pairs(currentlyDetectedKeys) do
					if string.match(currentKey, "^" .. entityUuid .. ":") then
						hasCurrentDetection = true
						break
					end
				end
				
				if not hasCurrentDetection then
					self:lowerDetection(key, deltaTime)
				else
					self.detectionLevels[key] = nil
				end
			else
				self:lowerDetection(key, deltaTime)
			end
		end
	end
end

function DetectionManagement.raiseDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number, entityPriorityInfo: EntityPriority
): ()
	local entityDetVal = self.detectionLevels[entityUuid] or 0
	if entityDetVal >= 1 then
		return
	end

	local entity = EntityManager.getEntityByUuid(entityPriorityInfo.entityUuid)
	local distance = entityPriorityInfo.distance

	if entity and entity.name == "Player" then
		local player = (entity :: EntityManager.DynamicEntity).instance :: Player
		local key = string.match(entityUuid, "^.-:(.+)$") :: string
		local highestStatus = PlayerStatusTypes.getStatusFromName(key)
		
		if not highestStatus then
			-- Does nothing, continue with normal detection raising
		else
			local previousStatus = playerStatusTracker[player]
			if previousStatus ~= highestStatus then
				playerStatusTracker[player] = highestStatus

				local instantRange = INSTANT_DETECTION_RULES[highestStatus] :: number
				if (instantRange and distance <= instantRange)
					or (QUICK_DETECTION_INSTANT_STATUSES[highestStatus] and distance <= QUICK_DETECTION_RANGE) then
					self.detectionLevels[entityUuid] = 1
					self:syncDetectionToClientIfPlayer(entityUuid)
					self.detectedSound:Play()
					return
				end
			end
		end
	end

	local speedMultiplier = entityPriorityInfo.speedMultiplier
	if distance <= QUICK_DETECTION_RANGE then
		speedMultiplier *= QUIK_DETECTION_MULTIPLIER
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
	local uuid = string.match(entityUuid, "^(.-):") :: string
	local entity = EntityManager.getEntityByUuid(uuid)
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

function DetectionManagement.createDetectedSound(agent: Agent): Sound
	local newSound = DETECTED_SOUND:Clone()
	newSound.Parent = agent:getPrimaryPart()
	return newSound
end

return DetectionManagement