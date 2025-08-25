--!nonstrict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)

local MIN_DISTANCE_FROM_PANIC_POS = 35

--[=[
	@class FleeToEscapePoints
]=]
local FleeToEscapePoints = {}
FleeToEscapePoints.__index = FleeToEscapePoints
FleeToEscapePoints.ClassName = "FleeToEscapePoints"

export type FleeToEscapePoints = typeof(setmetatable({} :: {
}, FleeToEscapePoints))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function FleeToEscapePoints.new(): FleeToEscapePoints
	return setmetatable({
		minDuration = 3,
		maxDuration = 3
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
	if agent:canBeIntimidated() then return false else return true end
end

function FleeToEscapePoints.canStillUse(self: FleeToEscapePoints, agent: Agent): boolean
	return not agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_INTIMIDATED)
end

function FleeToEscapePoints.doStart(self: FleeToEscapePoints, agent: Agent): ()
	local post = self:getPostWithMinimumDistanceFromPanicPos(agent)
	if post then
		agent.character.Humanoid.WalkSpeed = 19
		agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, true)
		agent:getNavigation():moveTo(post.cframe.Position)
	end
end

local function reflect(direction: Vector3, normal: Vector3): Vector3
	return direction - 2 * direction:Dot(normal) * normal
end

function FleeToEscapePoints.doStop(self: FleeToEscapePoints, agent: Agent): ()
	local panicPlayerSource = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_PLAYER_SOURCE):get()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_FLEEING, false)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.HAS_FLED, true)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.KILL_TARGET, panicPlayerSource)
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
		agent:getBodyRotationControl():setRotateTowards(panicPos)
		Debris:AddItem(Draw.raycast(agentPos, direction * maxDistance), 15)
	else
		local reflectedDirection = reflect(direction, rayResult.Normal).Unit
		local distanceToHit = (agentPos - rayResult.Position).Magnitude
		local distanceDifference = maxDistance - distanceToHit
		local finalPos = rayResult.Position + reflectedDirection * distanceDifference

		agent:getBodyRotationControl():setRotateTowards(finalPos)

		Debris:AddItem(Draw.line(agentPos, rayResult.Position, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.line(rayResult.Position, finalPos, Color3.new(0.184314, 0, 1)), 15)
		Debris:AddItem(Draw.point(finalPos, Color3.new(0.968627, 0, 1)), 15)
	end
end

function FleeToEscapePoints.doUpdate(self: FleeToEscapePoints, agent: Agent, deltaTime: number): ()
	return
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
					 -distanceFromAgent * 0.5    -- Closer to agent is slightly better
		
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