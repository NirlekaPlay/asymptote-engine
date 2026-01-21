--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Vec3 = require(ReplicatedStorage.shared.util.vector.Vec3)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local PatrolState = require(ServerScriptService.server.ai.behavior.patrol.PatrolState)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Optional = require(ServerScriptService.server.ai.memory.Optional)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local Node = require(ServerScriptService.server.ai.navigation.Node)

local MIN_RANDOM_WAIT_TIME = 16
local MAX_RANDOM_WAIT_TIME = 24
local STOP_GUARD_ANIM_BELOW = 2.5
local REACH_THRESHOLD = 4

--[=[
	@class WalkToRandomPost

	Makes a Guard walk to random unoccupied posts if not curious,
	confronting a trespasser, or threatened.
]=]
local WalkToRandomPost = {}
WalkToRandomPost.__index = WalkToRandomPost
WalkToRandomPost.ClassName = "WalkToRandomPost"

export type WalkToRandomPost = typeof(setmetatable({} :: {
	timeToReleasePost: number
}, WalkToRandomPost))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function WalkToRandomPost.new(): WalkToRandomPost
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
		timeToReleasePost = 0
	}, WalkToRandomPost)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.WALK_TARGET] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.IS_CURIOUS] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.DESIGNATED_POSTS] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.PATROL_STATE] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.POST_VACATE_COOLDOWN] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.TARGET_POST] = MemoryStatus.REGISTERED
}

function WalkToRandomPost.getMemoryRequirements(self: WalkToRandomPost): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function WalkToRandomPost.checkExtraStartConditions(self: WalkToRandomPost, agent: Agent): boolean
	return true
end

function WalkToRandomPost.canStillUse(self: WalkToRandomPost, agent: Agent): boolean
	local brain = agent:getBrain()
	return not (
		brain:hasMemoryValue(MemoryModuleTypes.IS_CURIOUS)
		or brain:hasMemoryValue(MemoryModuleTypes.PRIORITIZED_ENTITY)
	)
end

function WalkToRandomPost.doStart(self: WalkToRandomPost, agent: Agent): ()
	agent:getBrain():setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.RESUMING)
end

function WalkToRandomPost.doStop(self: WalkToRandomPost, agent: Agent): ()
	agent:getBodyRotationControl():setRotateToDirection(nil)
	WalkToRandomPost.setGuardAnimation(agent, false)

	if (agent:getBrain():getMemory(MemoryModuleTypes.PATROL_STATE):map(function(patrolState)
		return patrolState == PatrolState.WALKING
	end) :: Optional.Optional<boolean>):isPresent() then
		agent:getBrain():eraseMemory(MemoryModuleTypes.WALK_TARGET)
	end
end

function WalkToRandomPost.doUpdate(self: WalkToRandomPost, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local bodyRotControl = agent:getBodyRotationControl()

	local patrolState = brain:getMemory(MemoryModuleTypes.PATROL_STATE):get()
	local targetPost = brain:getMemory(MemoryModuleTypes.TARGET_POST):orElse(nil)
	local currentPost = brain:getMemory(MemoryModuleTypes.CURRENT_POST):orElse(nil)

	local isAtTargetPost = WalkToRandomPost.isAtTargetPost(agent, targetPost)

	if patrolState == PatrolState.RESUMING then
		if currentPost and WalkToRandomPost.isAtTargetPost(agent, currentPost) then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			patrolState = PatrolState.STAYING
			brain:setMemory(MemoryModuleTypes.PATROL_STATE, patrolState)
			bodyRotControl:setRotateToDirection(currentPost:getLookVector())
			WalkToRandomPost.setGuardAnimation(agent, true)
		elseif targetPost and targetPost:isOccupied() then
			if not isAtTargetPost then
				self:moveToPost(agent, targetPost)
			else
				bodyRotControl:setRotateToDirection(targetPost:getLookVector())
				brain:setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING)
				WalkToRandomPost.setGuardAnimation(agent, true)
			end
		else
			local post = self:getRandomUnoccupiedPost(agent, currentPost)
			if post then
				self:moveToPost(agent, post)
			end
		end
		return
	end

	if patrolState == PatrolState.WALKING and isAtTargetPost then
		self.timeToReleasePost = agent:getRandom():NextNumber(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)

		if targetPost then
			brain:setMemory(MemoryModuleTypes.CURRENT_POST, targetPost)
			bodyRotControl:setRotateToDirection(targetPost:getLookVector())
		end

		brain:setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING);
		WalkToRandomPost.setGuardAnimation(agent, true)
	elseif targetPost and patrolState == PatrolState.WALKING and not brain:hasMemoryValue(MemoryModuleTypes.WALK_TARGET) then
		self:moveToPost(agent, targetPost)
	elseif targetPost and patrolState == PatrolState.WALKING then
		if brain:hasMemoryValue(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE) and not brain:hasMemoryValue(MemoryModuleTypes.PATH) then
			brain:eraseMemory(MemoryModuleTypes.WALK_TARGET)
			brain:eraseMemory(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE)
			local post = self:getRandomUnoccupiedPost(agent, targetPost)
			if post then
				targetPost:vacate()
				self:moveToPost(agent, post)
			end
		end
	elseif patrolState == PatrolState.STAYING then
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			if currentPost then
				currentPost:vacate()
			end

			brain:eraseMemory(MemoryModuleTypes.TARGET_POST)
			brain:setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.UNEMPLOYED)
			bodyRotControl:setRotateToDirection(nil)
		elseif self.timeToReleasePost <= STOP_GUARD_ANIM_BELOW then
			WalkToRandomPost.setGuardAnimation(agent, false)
		end
	end

	if patrolState == PatrolState.UNEMPLOYED then
		local post = self:getRandomUnoccupiedPost(agent, currentPost)
		if post then
			self:moveToPost(agent, post)
		else
			brain:eraseMemory(MemoryModuleTypes.CURRENT_POST)
		end
	end

	brain:setMemory(MemoryModuleTypes.POST_VACATE_COOLDOWN, self.timeToReleasePost)
end

--

function WalkToRandomPost.moveToPost(self: WalkToRandomPost, agent: Agent, post: Node.Node): ()
	if Vec3.distManhattan(agent:getBlockPosition(), post:getBlockPosition()) <= REACH_THRESHOLD then
		self.timeToReleasePost = agent:getRandom():NextNumber(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)

		local brain = agent:getBrain()
		brain:setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING)
		brain:setMemory(MemoryModuleTypes.TARGET_POST, post)
		brain:setMemory(MemoryModuleTypes.CURRENT_POST, post)
		agent:getBodyRotationControl():setRotateToDirection(post:getLookVector())
		WalkToRandomPost.setGuardAnimation(agent, true)
		return
	end

	agent:getBrain():getMemory(MemoryModuleTypes.CURRENT_POST):ifPresent(function(post)
		post:vacate()
	end)

	post:occupy()
	agent:getBrain():eraseMemory(MemoryModuleTypes.CURRENT_POST)
	agent:getBrain():setMemory(MemoryModuleTypes.TARGET_POST, post)
	agent:getBrain():setMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.WALKING)
	agent:getBrain():setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromVector3(post.cframe.Position, 1, REACH_THRESHOLD))
end

function WalkToRandomPost.isAtTargetPost(agent: Agent, targetPost: Node.Node?): boolean
	if not targetPost then
		return false
	end

	if agent:getBrain():hasMemoryValue(MemoryModuleTypes.WALK_TARGET) then
		return false
	end

	local agentBlockPos = agent:getBlockPosition()
	local nodeBlockPos = targetPost:getBlockPosition()

	return Vec3.distManhattan(agentBlockPos, nodeBlockPos) <= REACH_THRESHOLD
end

function WalkToRandomPost.setGuardAnimation(agent: Agent, guardAnim: boolean): ()
	(agent :: any).character.isGuarding.Value = guardAnim
end

function WalkToRandomPost.getRandomUnoccupiedPost(self: WalkToRandomPost, agent: Agent, currentPost: Node.Node?): Node.Node?
	local chosenPost: Node.Node? = nil
	local count = 0
	local posts = agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get()

	for _, post in posts do
		if not post:isOccupied() and post ~= currentPost then
			count += 1
			if agent:getRandom():NextInteger(1, count) == 1 then
				chosenPost = post
			end
		end
	end

	return chosenPost
end

return WalkToRandomPost