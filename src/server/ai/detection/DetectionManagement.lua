--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local DetectionPayload = require(ReplicatedStorage.shared.network.payloads.DetectionPayload)

local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)
local DetectableSound = require(ServerScriptService.server.world.sound.DetectableSound)

local DEBUG_MODE = false
local DEBUG_DET_LEVELS = false
local BASE_DETECTION_TIME = 1.25
local QUICK_DETECTION_RANGE = 10
local QUIK_DETECTION_MULTIPLIER = 3.33
local CURIOUS_COOLDOWN_TIME = 2
local CURIOUS_THRESHOLD = 60 / 100
local DECAY_RATE_PER_SEC = 0.01 / 0.045 -- ≈ 0.222 (Sec. 1(d) of Plan doc.)
local INSTANT_DETECTION_RULES = {
	[PlayerStatusTypes.ARMED] = 20,             -- Pulling out a gun triggers instant detection within this distance
	[PlayerStatusTypes.DANGEROUS_ITEM] = 12.5   -- Carrying C4 triggers instant detection within this distance
}
local QUICK_DETECTION_INSTANT_STATUSES = {      -- Suspects with this status within the QUICK_DETECTION_RANGE will be instantly detected
	[PlayerStatusTypes.ARMED] = true
}
local DETECTED_SOUND = ReplicatedStorage.shared.assets.sounds.detection_alert

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
	GunShot = 9,
	Armed = 10,
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
	allDetectionBlocked: boolean,
	focusingTarget: EntityPriority?,
	curiousState: boolean,
	curiousCooldown: number,
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

type Agent = Agent.Agent

function DetectionManagement.new(agent: Agent): DetectionManagement
	return setmetatable({
		agent = agent,
		allDetectionBlocked = false,
		focusingTarget = nil :: (typeof(({} :: DetectionManagement).focusingTarget)),
		curiousState = false,
		curiousCooldown = 0,
		detectedEntities = {},
		detectionLevels = {},
		detectedSound = DetectionManagement.createDetectedSound(agent)
	}, DetectionManagement)
end

function DetectionManagement.blockAllDetection(self: DetectionManagement): ()
	self.allDetectionBlocked = true
end

function DetectionManagement.isCurious(self: DetectionManagement): boolean
	return self.curiousState
end

function DetectionManagement.getFocusingTarget(self: DetectionManagement)
	return self.focusingTarget
end

function DetectionManagement.eraseEntityStatusEntry(self: DetectionManagement, entityUuid: string, status: PlayerStatus.PlayerStatus): ()
	-- what the fuck. why.
	-- why did i make shit harder for myself.

	local entry = entityUuid .. ":" .. status.name
	self.detectionLevels[entry] = nil
end

function DetectionManagement.getHighestFullyDetectedEntity(self: DetectionManagement): EntityPriority?
	-- how convoluted can this file be??????
	-- does the fucking detection system need another FOURTH FUCKING REFACTOR??????
	-- this shouldve use another fucking function
	-- but holy shit i dont have enough mental sanity to refactor everything
	-- i need to get this shit DONE.
	local highest: EntityPriority? = nil

	for key, level in self.detectionLevels do
		if level >= 1 then
			local entityUuid, statusName = string.match(key, "^(.-):(.+)$")
			if not entityUuid or not statusName then continue end

			local entity = EntityManager.getEntityByUuid(entityUuid)
			if not entity then continue end

			local priority = 0
			local speedMultiplier = 1.0
			if entity.name == "Player" then
				local ps = PlayerStatusTypes.getStatusFromName(statusName)
				if ps then
					priority = ps:getPriorityLevel()
					speedMultiplier = ps:getDetectionSpeedModifier()
				end
			elseif SPEED_MULTIPLIERS[statusName] then
				speedMultiplier = SPEED_MULTIPLIERS[statusName]
			end

			-- distance bullshit
			local distance = 0
			if entity.isStatic then
				distance = (entity.position - self.agent:getPrimaryPart().Position).Magnitude
			elseif entity.name == "Player" then
				distance = ((entity.instance :: Player).Character.PrimaryPart.Position - self.agent:getPrimaryPart().Position).Magnitude
			else
				distance = ((entity.instance :: BasePart).Position - self.agent:getPrimaryPart().Position).Magnitude
			end

			local candidate: EntityPriority = {
				entityUuid = entityUuid,
				status = statusName,
				priority = priority,
				distance = distance,
				speedMultiplier = speedMultiplier
			}

			if not highest then
				highest = candidate
			elseif candidate.priority > highest.priority then
				highest = candidate
			elseif candidate.priority == highest.priority and candidate.distance < highest.distance then
				highest = candidate
			end
		end
	end

	return highest
end

--[=[
	Gets the current detection level for a specific entity
	@param entityUuid string -- The entity's UUID
	@return number -- Detection level from 0.0 to 1.0, or 0 if not detected
]=]
function DetectionManagement.getDetectionLevel(self: DetectionManagement, entityUuid: string): number
	-- For players, find their current active status key
	local entity = EntityManager.getEntityByUuid(entityUuid)
	if entity and entity.name == "Player" then
		for key, level in pairs(self.detectionLevels) do
			if string.match(key, "^" .. entityUuid .. ":") then
				return level
			end
		end
		return 0
	else
		-- For non-players, check all possible status combinations
		local maxLevel = 0
		for key, level in pairs(self.detectionLevels) do
			if string.match(key, "^" .. entityUuid .. ":") and level > maxLevel then
				maxLevel = level
			end
		end
		return maxLevel
	end
end

--[=[
	Checks if the agent is currently detecting anything
	@return boolean
]=]
function DetectionManagement.isDetecting(self: DetectionManagement): boolean
	return next(self.detectionLevels) ~= nil
end

--[=[
	Gets all players currently being detected with a specific status
	@param statusName string -- The status name (e.g., "MinorTrespassing", "Armed")
	@return {Player} -- Array of players with that status
]=]
function DetectionManagement.getPlayersWithStatus(self: DetectionManagement, statusName: string): {Player}
	local players = {}
	
	for key, _ in pairs(self.detectionLevels) do
		local entityUuid, status = string.match(key, "^(.-):(.+)$")
		if status == statusName then
			local entity = EntityManager.getEntityByUuid(entityUuid :: string)
			if entity and entity.name == "Player" then
				table.insert(players, (entity :: EntityManager.DynamicEntity).instance :: Player)
			end
		end
	end
	
	return players
end

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
			if playerStatus == PlayerStatusTypes.DISGUISED then
				local canDetect = self:canAgentDetectThroughDisguise(entityObject, detectionProfile)
				if not canDetect then
					continue
				end
			end
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
	elseif self.agent.hearingSounds[entityObject.uuid] then -- TODO: What the fuck is this.
		local soundEntity = self.agent.hearingSounds[entityObject.uuid] -- OH GOD NO
		local cost = soundEntity.cost :: number
		local soundType = soundEntity.soundType :: DetectableSound.DetectableSound
		local priority = 0
		local multiplier = 1.0
		if soundType == DetectableSound.Profiles.GUN_SHOT_UNSUPPRESSED then
			priority = STATUS_PRIORITIES["GunShot"]
			multiplier = 100
		end
		table.insert(results, {
			entityUuid = entityUuid,
			status = soundType.name,
			priority = priority,
			distance = distance,
			speedMultiplier = multiplier
		})
	else
		warn(`DetectionManagement :: UNRECOGNISED_ENTITY : {entityObject}`)
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

function DetectionManagement.canAgentDetectThroughDisguise(
	self: DetectionManagement,
	entity: EntityManager.DynamicEntity,
	detectionProfile: DetectionProfile
): boolean
	if not detectionProfile.isVisible then
		return false
	end

	local playerInstance = entity.instance :: Player
	local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(playerInstance)
	if not playerStatusHolder then
		warn(`cant evaluate disguise: status holder for {playerInstance.Name} is nil... thats not supposed to happen.`)
		return false
	end

	local currentDisguise = playerStatusHolder:getDisguise() :: string -- impossible if its empty
	local agentEnforceClass = (self.agent :: any).enforceClass -- it exists shut up.
	if not agentEnforceClass[currentDisguise] then
		if DEBUG_MODE then
			print(`{self.agent:getCharacterName()}: {agentEnforceClass} does not have disguise config for {currentDisguise}`)
		end
		return false
	else
		local condition = agentEnforceClass[currentDisguise]
		local currentAlertLevel = Mission.getAlertLevel()
		local alertValue = Mission.getAlertLevelNumericValue(currentAlertLevel)
		if DEBUG_MODE then
			print(`{self.agent:getCharacterName()}: Trying to see if it can see through disguise of '{currentDisguise}'.\n Current alert level: {alertValue} which coresponds to '{currentAlertLevel.name}'\nCondition is {condition}`)
		end
		-- bother even trying?
		if condition >= 5 then
			return true -- Always sees through
		elseif condition == 4 and alertValue >= 3 then -- SEARCHING or higher
			return true
		elseif condition == 3 and alertValue >= 0 then -- CALM or higher (always)
			return true
		elseif condition == 2 and alertValue >= 1 then -- NORMAL or higher
			return true
		elseif condition == 1 and alertValue >= 2 then -- ALERT or higher
			return true
		end
	end

	return false
end

function DetectionManagement.update(self: DetectionManagement, deltaTime: number): ()
	self:updateDetectionPerEntities(deltaTime)
	self:updateCuriousState(deltaTime)
	if DEBUG_DET_LEVELS then
		if next(self.detectionLevels) ~= nil then
			print(self.detectionLevels)
		end
	end
end

function DetectionManagement.updateDetectionPerEntities(self: DetectionManagement, deltaTime: number): ()
    local currentlyDetectedKeys: { [string]: true } = {}
    
    if not self.allDetectionBlocked then
        local focusTarget = self:findHighestPriorityEntity()
        self.focusingTarget = focusTarget

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
                    
					-- Step 1: Check for any maxed higher priority status, override highestPriorityInfo if found
					local highestPriority = highestPriorityInfo.priority
					for key, level in pairs(self.detectionLevels) do
						if string.match(key, "^" .. entityUuid .. ":") then
							local keyStatus = string.match(key, "^.-:(.+)") :: string
							-- Assuming you have a way to get priority from status string
							local keyPriority = (PlayerStatusTypes.getStatusFromName(keyStatus) :: PlayerStatus.PlayerStatus):getPriorityLevel()
							if keyPriority > highestPriority and level >= 1.0 then
								highestPriorityInfo = {
									entityUuid = entityUuid,
									status = keyStatus,
									priority = keyPriority
								}
								highestPriority = keyPriority
								currentKey = key
								break
							end
						end
					end
					
					-- Step 2: Build list of currently detected statuses for this player
					local detectedStatuses: { [string]: true } = {}
					detectedStatuses[highestPriorityInfo.status] = true
					
					-- Add all other currently detected statuses from infos
					for _, info in ipairs(infos) do
						detectedStatuses[info.status] = true
					end
					
					-- Step 3: For each status no longer detected, transfer detection to detected status of closest priority
					for key, level in pairs(self.detectionLevels) do
						if string.match(key, "^" .. entityUuid .. ":") then
							local keyStatus = string.match(key, "^.-:(.+)") :: string
							if not detectedStatuses[keyStatus] then
								-- Find detected status with closest priority to keyStatus
								local statusPriority = (PlayerStatusTypes.getStatusFromName(keyStatus) :: PlayerStatus.PlayerStatus):getPriorityLevel()
								local candidateStatus: string? = nil
								local bestDistance = math.huge
								
								for detectedStatus, _ in pairs(detectedStatuses) do
									local detectedPriority = (PlayerStatusTypes.getStatusFromName(detectedStatus) :: PlayerStatus.PlayerStatus):getPriorityLevel()
									local currentDistance = math.abs(detectedPriority - statusPriority)
									if currentDistance < bestDistance then
										candidateStatus = detectedStatus
										bestDistance = currentDistance
									end
								end
								
								-- Transfer detection to candidateStatus if exists and detection is not maxed
								if candidateStatus and candidateStatus ~= keyStatus then
									local candidateKey = entityUuid .. ":" .. candidateStatus
									if level < 1.0 then
										self.detectionLevels[candidateKey] = math.min(1.0, (self.detectionLevels[candidateKey] or 0) + level)
									else
										self.detectionLevels[candidateKey] = self.detectionLevels[candidateKey] or 0
									end
								end
								
								-- Remove old status if detection is not maxed
								if level < 1.0 and (candidateStatus and self.detectionLevels[entityUuid .. ":" .. candidateStatus] < 1) then
									self.detectionLevels[key] = nil
								end
							end
						end
					end
					
					-- Step 4: Transfer detection FROM lower priority statuses TO highestPriorityInfo before removal
					for key, level in pairs(self.detectionLevels) do
						if string.match(key, "^" .. entityUuid .. ":") and key ~= currentKey then
							local keyStatus = string.match(key, "^.-:(.+)") :: string
							local keyPriority = (PlayerStatusTypes.getStatusFromName(keyStatus) :: PlayerStatus.PlayerStatus):getPriorityLevel()
							if keyPriority < highestPriority and level < 1.0 then
								-- Transfer detection to highestPriorityInfo before removing
								self.detectionLevels[currentKey] = math.max(self.detectionLevels[currentKey] or 0, level)
                                self.detectionLevels[key] = nil
                            end
                        end
                    end

					-- Step 5: Ensure highestPriorityInfo detection level initialized
                    if self.detectionLevels[currentKey] == nil then
                        self.detectionLevels[currentKey] = 0
                    end
                    
                    currentlyDetectedKeys[currentKey] = true
                    
					-- Step 6: Raise detection on highestPriorityInfo
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
				-- Non-player entities (DeadBody, C4, etc.) - no stacking rules apply
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
    end

	-- Clean up detection levels that are no longer being tracked
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
					self:lowerDetection(key, deltaTime)
            end
			else
				self:lowerDetection(key, deltaTime)
			end
        end
    end
end

function DetectionManagement.updateCuriousState(self: DetectionManagement, deltaTime: number): ()
	local focusTarget = self.focusingTarget

	if focusTarget then
		local focusKey = focusTarget.entityUuid .. ":" .. focusTarget.status
		local focusDetectionLevel = self.detectionLevels[focusKey] or 0
		
		if focusDetectionLevel >= CURIOUS_THRESHOLD then
			self.curiousState = true
			self.curiousCooldown = CURIOUS_COOLDOWN_TIME
		end
	else
		if self.curiousState and self.curiousCooldown > 0 then
			self.curiousCooldown -= deltaTime
		end
	end

	if self.curiousCooldown <= 0 then
		self.curiousState = false
	end
end

function DetectionManagement.raiseDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number, entityPriorityInfo: EntityPriority
): ()
	local entityDetVal = self.detectionLevels[entityUuid] or 0
	if entityDetVal >= 1 then
		return
	end

	local gotInstantlyDetected = self:handleInstantDetection(entityUuid, entityPriorityInfo)
	if gotInstantlyDetected then
		return
	end

	local speedMultiplier = entityPriorityInfo.speedMultiplier
	local detectionProfile = self.detectedEntities[entityPriorityInfo.entityUuid]
	local isEntityVisible = detectionProfile.isVisible
	local distance = entityPriorityInfo.distance

	if detectionProfile and detectionProfile.isHeard and not isEntityVisible then
		local playerInst = EntityUtils.ifPlayerThenGet(EntityManager.getEntityByUuid(entityPriorityInfo.entityUuid))
		if playerInst and playerInst.Character then
			local humanoid = (playerInst.Character :: Model):FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- NOTES: Detection speed multiplier by walk speed
				-- TODO: should be handled in a seperate code.

				speedMultiplier *= math.map(humanoid.WalkSpeed, 16, 24, 1, 3)
			end
		end
	end

	if isEntityVisible and distance <= QUICK_DETECTION_RANGE then
		speedMultiplier *= QUIK_DETECTION_MULTIPLIER
	end

	local detectionSpeed = speedMultiplier
	local progressRate = (1 / BASE_DETECTION_TIME) * detectionSpeed

	entityDetVal = math.clamp(entityDetVal + progressRate * deltaTime, 0.0, 1.0)
	self.detectionLevels[entityUuid] = entityDetVal
	self:syncDetectionToClientIfPlayer(entityUuid)
	if entityDetVal >= 1 then
		local isPlayer = EntityUtils.isPlayer(EntityManager.getEntityByUuid(entityPriorityInfo.entityUuid))

		if isPlayer then
			self.detectedSound:Play()
		end
	end
end

function DetectionManagement.handleInstantDetection(
	self: DetectionManagement, entityKey: string, entityPriorityInfo: EntityPriority
): boolean
	local entity = EntityManager.getEntityByUuid(entityPriorityInfo.entityUuid)
	local distance = entityPriorityInfo.distance

	if not entity or entity.name ~= "Player" then
		return false
	end

	local status = string.match(entityKey, "^.-:(.+)$") :: string
	local highestStatus = PlayerStatusTypes.getStatusFromName(status)

	if not highestStatus then
		return false
	end

	local player = (entity :: EntityManager.DynamicEntity).instance :: Player
	
	-- Status tracker update
	-- TODO: Keep this separate.
	local previousStatus = playerStatusTracker[player]
	if previousStatus ~= highestStatus then
		playerStatusTracker[player] = highestStatus
	end
	
	local instantRange = INSTANT_DETECTION_RULES[highestStatus] :: number
	
	if (instantRange and distance <= instantRange)
		or (QUICK_DETECTION_INSTANT_STATUSES[highestStatus] and distance <= QUICK_DETECTION_RANGE) then
		
		self.detectionLevels[entityKey] = 1
		self:syncDetectionToClientIfPlayer(entityKey)
		self.detectedSound:Play()

		return true
	end

	return false
end

function DetectionManagement.lowerDetection(
	self: DetectionManagement, entityUuid: string, deltaTime: number
): ()
	local level = self.detectionLevels[entityUuid]
	if not level or level >= 1 then
		return
	end
	
	local finalDet = math.max(0, level - DECAY_RATE_PER_SEC * deltaTime)
	if finalDet > 0 then
		self.detectionLevels[entityUuid] = finalDet
	else
		self.detectionLevels[entityUuid] = nil
	end

	self:syncDetectionToClientIfPlayer(entityUuid)
end

--

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