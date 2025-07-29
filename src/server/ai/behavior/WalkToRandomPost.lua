--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)

--[=[
	@class WalkToRandomPost

	Makes a Guard walk to random unoccupied posts if not curius
	or threatened.
]=]
local WalkToRandomPost = {}
WalkToRandomPost.__index = WalkToRandomPost

export type WalkToRandomPost = typeof(setmetatable({} :: {
	diedConnection: RBXScriptConnection?,
	previousPost: GuardPost?,
	isAtTargetPost: boolean,
	pathToPost: Path?,
	timeToReleasePost: number
}, WalkToRandomPost))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type GuardPost = GuardPost.GuardPost
type Agent = Agent.Agent

function WalkToRandomPost.new(): WalkToRandomPost
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		--
		diedConnection = nil,
		previousPost = nil,
		isAtTargetPost = false,
		pathToPos = nil,
		timeToReleasePost = 0
	}, WalkToRandomPost)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_CURIOUS] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.DESIGNATED_POSTS] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TARGET_POST] = MemoryStatus.REGISTERED
}

local MIN_RANDOM_WAIT_TIME = 5
local MAX_RANDOM_WAIT_TIME = 10

function WalkToRandomPost.getMemoryRequirements(self: WalkToRandomPost): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function WalkToRandomPost.checkExtraStartConditions(self: WalkToRandomPost, agent: Agent): boolean
	return true
end

function WalkToRandomPost.canStillUse(self: WalkToRandomPost, agent: Agent): boolean
	return agent:getBrain():checkMemory(MemoryModuleTypes.IS_CURIOUS, MemoryStatus.VALUE_ABSENT)
end

function WalkToRandomPost.doStart(self: WalkToRandomPost, agent: Agent): ()
	self:connectDiedConnection(agent)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.PATROL_STATE, "RESUMING")
end

function WalkToRandomPost.doStop(self: WalkToRandomPost, agent: Agent): ()
	agent:getBodyRotationControl():setRotateToDirection(nil)
	agent:getNavigation():stop()
end

function WalkToRandomPost.doUpdate(self: WalkToRandomPost, agent: Agent, deltaTime: number): ()
	local nav = agent:getNavigation()
	local rot = agent:getBodyRotationControl()
	local brain = agent:getBrain()
	local targetPost = brain:getMemory(MemoryModuleTypes.TARGET_POST):get()
	local patrolState = brain:getMemory(MemoryModuleTypes.PATROL_STATE):get():getValue()

	if patrolState == "RESUMING" then
		-- TODO: Add cooldown to begin patrolling again after interruption if necessary

		if targetPost and targetPost:getValue():isOccupied() then
			if (not self.isAtTargetPost) or (self.isAtTargetPost and nav:getPath() ~= self.pathToPost) then
				self:moveToPost(agent, targetPost:getValue())
			else
				rot:setRotateToDirection(targetPost:getValue().cframe.LookVector)
				brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, "STAYING")
			end
		else
			local post = self:getRandomUnoccupiedPost(agent)
			if post then
				self:moveToPost(agent, post)
			end
		end

		return -- prevent further logic this frame
	end
	
	if patrolState == "WALKING" and nav.finished and not self.isAtTargetPost then
		nav.finished = false
		brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, "STAYING")
		self.isAtTargetPost = true
		self.timeToReleasePost = math.random(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)
		rot:setRotateToDirection(targetPost:getValue().cframe.LookVector)
	elseif patrolState == "STAYING" then
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, "UNEMPLOYED")
			self.previousPost = targetPost:getValue()
			brain:setNullableMemory(MemoryModuleTypes.TARGET_POST, nil)
			self.isAtTargetPost = false
			rot:setRotateToDirection(nil)
		end
	end

	if brain:getMemory(MemoryModuleTypes.PATROL_STATE):get():getValue() == "UNEMPLOYED" then
		local post = self:getRandomUnoccupiedPost(agent)
		if post then
			self:moveToPost(agent, post)
		end
	end

	brain:setNullableMemory(MemoryModuleTypes.POST_VACATE_COOLDOWN, (string.format("%.2f", self.timeToReleasePost)))
end

--

function WalkToRandomPost.moveToPost(self: WalkToRandomPost, agent: Agent, post: GuardPost): ()
	post:occupy()
	self.isAtTargetPost = false
	if self.previousPost then
		self.previousPost:vacate()
	end
	agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGET_POST, post)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.PATROL_STATE, "WALKING")
	agent:getNavigation():moveTo(post.cframe.Position)
	self.pathToPost = agent:getNavigation():getPath()
end

function WalkToRandomPost.getRandomUnoccupiedPost(self: WalkToRandomPost, agent: Agent): GuardPost?
	local unoccupied = {}

	for _, post in ipairs(agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get():getValue()) do
		if not post:isOccupied() then
			table.insert(unoccupied, post)
		end
	end

	if #unoccupied == 0 then
		return nil
	end

	return unoccupied[math.random(1, #unoccupied)]
end

function WalkToRandomPost.connectDiedConnection(self: WalkToRandomPost, agent: Agent): ()
	if not self.diedConnection then
		local humanoid = agent.character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self.diedConnection = humanoid.Died:Once(function()
				local targetPost = agent:getBrain():getMemory(MemoryModuleTypes.TARGET_POST)
				if targetPost:isPresent() then
					targetPost:get():getValue():vacate()
				end

				if agent:getBrain():getMemory(MemoryModuleTypes.PATROL_STATE) == "UNEMPLOYED" then
					if self.previousPost then
						self.previousPost:vacate()
					end
				end
			end)
		end
	end
end

return WalkToRandomPost