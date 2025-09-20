--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugEntityNameGenerator = require(ReplicatedStorage.shared.network.DebugEntityNameGenerator)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

local MIN_DISTANCE_TO_ESCAPE_POS = 5
local MIN_DISTANCE_FROM_PANIC_POS = 45
local DIST_CHECK_UPDATE_INTERVAL = 0.5

--[=[
	@class FleeToEscapePoints
]=]
local FleeToEscapePoints = {}
FleeToEscapePoints.__index = FleeToEscapePoints
FleeToEscapePoints.ClassName = "FleeToEscapePoints"

export type FleeToEscapePoints = typeof(setmetatable({} :: {
	timeAccum: number
}, FleeToEscapePoints))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent

function FleeToEscapePoints.new(): FleeToEscapePoints
	return setmetatable({
		minDuration = 4,
		maxDuration = 6,
		timeAccum = 0
	}, FleeToEscapePoints)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_FLEEING] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.DESIGNATED_POSTS] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.PANIC_POSITION] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.HAS_FLED] = MemoryStatus.VALUE_ABSENT
}

function FleeToEscapePoints.getMemoryRequirements(self: FleeToEscapePoints): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function FleeToEscapePoints.checkExtraStartConditions(self: FleeToEscapePoints, agent: Agent): boolean
	return true
end

function FleeToEscapePoints.canStillUse(self: FleeToEscapePoints, agent: Agent): boolean
	return not (agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_INTIMIDATED)
		or agent:getBrain():hasMemoryValue(MemoryModuleTypes.KILL_TARGET))
end

function FleeToEscapePoints.doStart(self: FleeToEscapePoints, agent: Agent): ()
	local post = self:getPostWithMinimumDistanceFromPanicPos(agent)
	if post then
		agent.character.Humanoid.WalkSpeed = 19
		agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, true)
		agent:getNavigation():moveTo(post.cframe.Position)
		agent:getBrain():setNullableMemory(MemoryModuleTypes.FLEE_TO_POSITION, post.cframe.Position)
		Debris:AddItem(Draw.point(post.cframe.Position, Color3.new(0, 1, 0)), 5)
	else
		local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
		if not panicSourceTargetToKill:isPresent() then
			return
		end
		local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
		if not entityObj then
			error("Panic source entity is nil")
		end
		if not entityObj.isStatic and entityObj.name == "Player" then
			local player = Players:GetPlayerByUserId(tonumber(entityObj.uuid) :: number)
			agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, player)
		end
	end
end

local function reflect(direction: Vector3, normal: Vector3): Vector3
	return direction - 2 * direction:Dot(normal) * normal
end

function FleeToEscapePoints.doStop(self: FleeToEscapePoints, agent: Agent): ()
	-- Breaks DRY!!!!
	local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
	if not panicSourceTargetToKill:isPresent() then
		return
	end
	local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
	if not entityObj then
		error("Panic source entity is nil")
	end
	if not entityObj.isStatic and entityObj.name == "Player" then
		local player = Players:GetPlayerByUserId(entityObj.uuid)
		agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, player)
	end
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, false)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.HAS_FLED, true)
	agent:getNavigation():stop()
	agent:getFaceControl():setFace("Angry")

	local maxDistance = 25
	local panicPos = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get()
	local agentPos = agent:getPrimaryPart().Position
	local direction = (panicPos - agentPos).Unit
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { agent.character }
	local rayResult = workspace:Raycast(agentPos, direction * maxDistance, rayParams)
	if not rayResult then
		agent:getGunControl():lookAt(panicPos)
		agent:getBodyRotationControl():setRotateTowards(panicPos)
		Debris:AddItem(Draw.raycast(agentPos, direction * maxDistance), 15)
	else
		local reflectedDirection = reflect(direction, rayResult.Normal).Unit
		local distanceToHit = (agentPos - rayResult.Position).Magnitude
		local distanceDifference = maxDistance - distanceToHit
		local finalPos = rayResult.Position + reflectedDirection * distanceDifference
		agent:getGunControl():lookAt(finalPos)
		agent:getBodyRotationControl():setRotateTowards(finalPos)

		Debris:AddItem(Draw.line(agentPos, rayResult.Position, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.line(rayResult.Position, finalPos, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.point(finalPos, Color3.new(0.968627, 0, 1)), 15)
	end
end

function FleeToEscapePoints.doUpdate(self: FleeToEscapePoints, agent: Agent, deltaTime: number): ()
	self.timeAccum += deltaTime
	if self.timeAccum >= DIST_CHECK_UPDATE_INTERVAL then
		self.timeAccum = 0

		local fleeToPos = agent:getBrain():getMemory(MemoryModuleTypes.FLEE_TO_POSITION)
		if fleeToPos:isEmpty() then
			print("flee to pos is empty")
			return
		end

		local distance = (agent:getPrimaryPart().Position - fleeToPos:get()).Magnitude
		if distance <= MIN_DISTANCE_TO_ESCAPE_POS then
			print(`{DebugEntityNameGenerator.getEntityName(agent)} is in minimum distance to escape point position \n with distance of {distance}`)
			local panicSourceTargetToKill = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID)
			if not panicSourceTargetToKill:isPresent() then
				return
			end
			local entityObj = EntityManager.getEntityByUuid(panicSourceTargetToKill:get())
			if not entityObj then
				error("Panic source entity is nil")
			end
			if not entityObj.isStatic and entityObj.name == "Player" then
				local player = Players:GetPlayerByUserId(entityObj.uuid)
				agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, player)
			end
		end
	end
end

--

function FleeToEscapePoints.getPostWithMinimumDistanceFromPanicPos(self: FleeToEscapePoints, agent: Agent): GuardPost.GuardPost?
	local posts = agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get()
	local panicPos = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get()
	local agentPos = agent:getPrimaryPart().Position
	local currentPost = agent:getBrain():getMemory(MemoryModuleTypes.TARGET_POST):get()
	
	local bestPost = nil
	local bestScore = -math.huge
	
	for i, post in ipairs(posts) do
		if post == currentPost then
			continue
		end
		
		local postPos = post.cframe.Position-- Assuming posts have a getPosition method
		
		-- Calculate distance from panic position to this post
		local distanceFromPanic = (postPos - panicPos).Magnitude
		
		-- Calculate direction away from panic (dot product for directional preference)
		local panicToAgent = (agentPos - panicPos).Unit
		local agentToPost = (postPos - agentPos).Unit
		local directionalBonus = panicToAgent:Dot(agentToPost) -- Positive if same direction (away from panic)
		
		-- Calculate distance from agent to post (prefer closer posts for faster escape)
		local distanceFromAgent = (postPos - agentPos).Magnitude
		
		-- Scoring system (higher = better)
		local score = distanceFromPanic * 1.0 +  -- Further from panic is better
					 directionalBonus * 20.0 +   -- Same direction as fleeing is much better
					 -distanceFromAgent * 0.5 +   -- Closer to agent is slightly better
					 Random.new(tick()):NextNumber(-5, 5) -- Add randomization
		
		-- Only consider posts that meet minimum distance requirement
		if distanceFromPanic >= MIN_DISTANCE_FROM_PANIC_POS and score > bestScore then
			bestScore = score
			bestPost = post
		end
	end
	
	-- Fallback: if no post meets criteria, pick the furthest one
	if bestPost == nil then
		local furthestDistance = 0
		for i, post in ipairs(posts) do
			if post == currentPost then continue end
			local postPos = post.cframe.Position
			local distance = (postPos - panicPos).Magnitude
			if distance > furthestDistance then
				furthestDistance = distance
				bestPost = post
			end
		end
	end
	
	if bestPost then
		print("Selected escape post with distance:", (bestPost.cframe.Position - panicPos).Magnitude)
	end
	
	return bestPost
end

-- a more simpler approach if we just want basic "run away" behavior.
function FleeToEscapePoints.getPostAwayFromPanic(self: FleeToEscapePoints, agent: Agent): GuardPost.GuardPost?
	local posts = agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get()
	local panicPos = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get()
	local agentPos = agent:getPrimaryPart().Position
	local currentPost = agent:getBrain():getMemory(MemoryModuleTypes.TARGET_POST):get()
	
	-- Find the post that's furthest from panic position and reasonably accessible
	local bestPost = nil
	local bestDistance = 0
	
	for i, post in ipairs(posts) do
		if post == currentPost then continue end

		local postPos = post.cframe.Position
		local distanceFromPanic = (postPos - panicPos).Magnitude
		local distanceFromAgent = (postPos - agentPos).Magnitude
		
		-- Prefer posts that are far from panic but not too far from agent
		local suitability = distanceFromPanic - (distanceFromAgent * 0.3)
		
		if suitability > bestDistance then
			bestDistance = suitability
			bestPost = post
		end
	end
	
	return bestPost
end

return FleeToEscapePoints