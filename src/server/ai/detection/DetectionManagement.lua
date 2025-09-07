--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DetectionPayload = require(ReplicatedStorage.shared.network.DetectionPayload)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local BASE_DETECTION_TIME = 1.25
local DECAY_RATE_PER_SEC = 1 / 0.045

local detectionDataBatch: { [Player]: {DetectionPayload.DetectionData} } = {}

--[=[
	@class DetectionManagement
]=]
local DetectionManagement = {}
DetectionManagement.__index = DetectionManagement

export type DetectionManagement = typeof(setmetatable({} :: {
	agent: DetectionAgent.DetectionAgent,
	detectedEntities: { [string]: DetectionProfile },
	detectionLevels: { [string]: number } -- string is the entity uuid
}, DetectionManagement))

type DetectionProfile = {
	isHeard: boolean?,
	isVisible: boolean?
}

function DetectionManagement.new(agent: DetectionAgent.DetectionAgent): DetectionManagement
	return setmetatable({
		agent = agent,
		detectedEntities = {},
		detectionLevels = {}
	}, DetectionManagement)
end

-- big brother be watchin you
-- "deprecated"
-- big brother can suck myy toes
-- hes my fatha
function DetectionManagement.addOrUpdateDetectedEntities(
	self: DetectionManagement, entities: { string }
): ()
	
	for _, entityUuid in ipairs(entities) do
		self.detectedEntities[entityUuid] = { isVisible = true }
	end

	return
end

function DetectionManagement.update(self: DetectionManagement, deltaTime: number): ()
	-- all apis:

	for entityUuid, detectionProfile in pairs(self.detectedEntities) do
		local entityObject = EntityManager.getEntityByUuid(entityUuid)

		if not entityObject then return end

		if entityObject.name == "Player" then
			entityObject = entityObject :: EntityManager.DynamicEntity

			-- getting the player statuses
			local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(entityObject.instance :: Player)
			local highestDetectableStatus = playerStatusHolder:getHighestDetectableStatus(
				detectionProfile.isVisible or false, detectionProfile.isHeard or false
			) -- could be nil

			if highestDetectableStatus then
				self:raiseDetection(entityUuid, deltaTime, 0)
			else -- test purpose sonly
				self:lowerDetection(entityUuid, deltaTime)
			end
		else
			if detectionProfile.isVisible or detectionProfile.isHeard then
				self:raiseDetection(entityUuid, deltaTime, 0)
			else
				self:lowerDetection(entityUuid, deltaTime)
			end
		end
	end
end

function DetectionManagement.sort(self: DetectionManagement): ()
	
end

function DetectionManagement.raiseDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number, speedModifier: number
): ()

	-- just use the old logic from now on
	local detectionSpeed = 1 + (speedModifier / 100)
	local progressRate = (1 / BASE_DETECTION_TIME) * detectionSpeed
	local entityDetVal = self.detectionLevels[entityUuid] or 0
	
	entityDetVal = math.clamp(entityDetVal + progressRate * deltaTime, 0.0, 1.0)
	self.detectionLevels[entityUuid] = entityDetVal
	self:syncDetectionToClientIfPlayer(entityUuid)
end

function DetectionManagement.lowerDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number
): ()
	local level = self.detectionLevels[entityUuid] or 0
	if level >= 1 then return end
	-- magicc
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
	if not entity then
		return
	end

	if entity.name == "Player" then
		entity = entity :: EntityManager.DynamicEntity
		DetectionManagement.addToBatch(entity.instance :: Player, {
			character = self.agent.character,
			uuid = (self.agent :: any):getUuid() :: string,
			detectionValue = self.detectionLevels[entityUuid] or 0
		})
	end
end

--

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

return DetectionManagement