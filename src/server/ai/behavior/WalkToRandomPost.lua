--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local PatrolState = require(ServerScriptService.server.ai.behavior.patrol.PatrolState)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local Node = require(ServerScriptService.server.ai.navigation.Node)

local REACH_THRESHOLD = 3

--[=[
	@class WalkToRandomPost

	Makes a Guard walk to random unoccupied posts if not curious,
	confronting a trespasser, or threatened.
]=]
local WalkToRandomPost = {}
WalkToRandomPost.__index = WalkToRandomPost
WalkToRandomPost.ClassName = "WalkToRandomPost"

export type WalkToRandomPost = typeof(setmetatable({} :: {
	diedConnection: RBXScriptConnection?,
	destroyedConnection: RBXScriptConnection?,
	previousPost: Node?,
	isAtTargetPost: boolean,
	pathToPost: Path?,
	timeToReleasePost: number
}, WalkToRandomPost))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Node = Node.Node
type Agent = Agent.Agent

function WalkToRandomPost.new(): WalkToRandomPost
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		--
		diedConnection = nil :: RBXScriptConnection?,
		previousPost = nil :: Node.Node?,
		isAtTargetPost = false,
		pathToPos = nil :: Path?,
		timeToReleasePost = 0
	}, WalkToRandomPost) :: any -- stfu typechecker your fucking errors means jackshit
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_CURIOUS] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.DESIGNATED_POSTS] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.TARGET_POST] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PRIORITIZED_ENTITY] = MemoryStatus.VALUE_ABSENT
}

local MIN_RANDOM_WAIT_TIME = 5
local MAX_RANDOM_WAIT_TIME = 10

function WalkToRandomPost.getMemoryRequirements(self: WalkToRandomPost): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function WalkToRandomPost.checkExtraStartConditions(self: WalkToRandomPost, agent: Agent): boolean
	return not (agent:getBrain():hasMemoryValue(MemoryModuleTypes.CONFRONTING_TRESPASSER) and
		agent:getBrain():hasMemoryValue(MemoryModuleTypes.IS_PANICKING))
end

function WalkToRandomPost.canStillUse(self: WalkToRandomPost, agent: Agent): boolean
	local brain = agent:getBrain()
	return not (
		brain:checkMemory(MemoryModuleTypes.IS_PANICKING, MemoryStatus.VALUE_PRESENT)
		or brain:checkMemory(MemoryModuleTypes.IS_COMBAT_MODE, MemoryStatus.VALUE_PRESENT)
		or brain:checkMemory(MemoryModuleTypes.IS_CURIOUS, MemoryStatus.VALUE_PRESENT)
		or brain:checkMemory(MemoryModuleTypes.PRIORITIZED_ENTITY, MemoryStatus.VALUE_PRESENT)
	)
end

function WalkToRandomPost.doStart(self: WalkToRandomPost, agent: Agent): ()
	self:connectDiedConnection(agent)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.RESUMING)
end

function WalkToRandomPost.doStop(self: WalkToRandomPost, agent: Agent): ()
	agent:getBodyRotationControl():setRotateToDirection(nil)
	agent:getBrain():eraseMemory(MemoryModuleTypes.WALK_TARGET); -- NOTES: May cause problems. FIx this shit later by storing a path instance.
	-- TODO: Instances of this are to be replaced with propper animation handling.
	(agent :: any).character.isGuarding.Value = false
end

function WalkToRandomPost.doUpdate(self: WalkToRandomPost, agent: Agent, deltaTime: number): ()
	local nav = agent:getNavigation()
	local rot = agent:getBodyRotationControl()
	local brain = agent:getBrain()

	local targetPostMemory = brain:getMemory(MemoryModuleTypes.TARGET_POST)
	local patrolStateMemory = brain:getMemory(MemoryModuleTypes.PATROL_STATE)
	local currentPostMemory = brain:getMemory(MemoryModuleTypes.CURRENT_POST)

	local targetPost = targetPostMemory:orElse(nil)
	local patrolState = patrolStateMemory:orElse(nil)
	local currentPost = currentPostMemory:orElse(nil)

	if not patrolState then
		patrolState = PatrolState.UNEMPLOYED
		brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, patrolState);
		(agent :: any).character.isGuarding.Value = false
	end

	if patrolState == PatrolState.RESUMING then
		if currentPost then
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			rot:setRotateToDirection(currentPost.cframe.LookVector)
			brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING);
			(agent :: any).character.isGuarding.Value = true
		elseif targetPost and targetPost:isOccupied() then
			if (not self.isAtTargetPost) or (self.isAtTargetPost and nav:getPath() ~= self.pathToPost) then
				self:moveToPost(agent, targetPost)
			else
				rot:setRotateToDirection(targetPost.cframe.LookVector)
				brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING);
				(agent :: any).character.isGuarding.Value = true
			end
		else
			local post = self:getRandomUnoccupiedPost(agent)
			if post then
				self:moveToPost(agent, post)
			end
		end
		return -- prevent further logic this frame
	end
	
	if patrolState == PatrolState.WALKING and nav:isDone() and not self.isAtTargetPost then
		self.isAtTargetPost = true
		self.timeToReleasePost = agent:getRandom():NextNumber(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)

		if targetPost then
			brain:setNullableMemory(MemoryModuleTypes.CURRENT_POST, targetPost)
			rot:setRotateToDirection(targetPost.cframe.LookVector)
		end

		brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING);
		(agent :: any).character.isGuarding.Value = true
	elseif patrolState == PatrolState.STAYING then
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			self.previousPost = brain:getMemory(MemoryModuleTypes.CURRENT_POST):orElse(nil)
			if self.previousPost then
				self.previousPost:vacate()
			end

			brain:setNullableMemory(MemoryModuleTypes.CURRENT_POST, nil)
			brain:setNullableMemory(MemoryModuleTypes.TARGET_POST, nil)
			brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.UNEMPLOYED)

			self.isAtTargetPost = false
			rot:setRotateToDirection(nil)
		end
	end


	if patrolState == PatrolState.UNEMPLOYED then
		local post = self:getRandomUnoccupiedPost(agent)
		if post then
			self:moveToPost(agent, post)
		end
	end

	brain:setNullableMemory(MemoryModuleTypes.POST_VACATE_COOLDOWN, self.timeToReleasePost)
end

--

function WalkToRandomPost.moveToPost(self: WalkToRandomPost, agent: Agent, post: Node): ()
	local rootPart = agent.character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		warn("WalkToRandomPost: Missing HumanoidRootPart for", agent.character)
		return
	end

	local distance = (rootPart.Position - post.cframe.Position).Magnitude

	-- Skip pathfinding if we're already close enough to the post
	if distance <= REACH_THRESHOLD then
		self.isAtTargetPost = true
		self.timeToReleasePost = agent:getRandom():NextNumber(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)

		local brain = agent:getBrain()
		brain:setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.STAYING)
		brain:setNullableMemory(MemoryModuleTypes.TARGET_POST, post)
		brain:setNullableMemory(MemoryModuleTypes.CURRENT_POST, post);
		agent:getBodyRotationControl():setRotateToDirection(post.cframe.LookVector);
		((agent :: any).character :: any).isGuarding.Value = true
		return
	end

	post:occupy()
	self.isAtTargetPost = false
	if self.previousPost then
		self.previousPost:vacate()
	end

	agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGET_POST, post)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.CURRENT_POST, nil)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.PATROL_STATE, PatrolState.WALKING)
	agent:getBrain():setMemory(MemoryModuleTypes.WALK_TARGET, WalkTarget.fromVector3(post.cframe.Position, 1, 0))
	self.pathToPost = nil
end

function WalkToRandomPost.getRandomUnoccupiedPost(self: WalkToRandomPost, agent: Agent): Node?
	local unoccupied = {}
	local count = 0

	for _, post in agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get() do
		if not post:isOccupied() then
			count += 1
			unoccupied[count] = post
		end
	end

	if count == 0 then
		return nil
	end

	return unoccupied[agent:getRandom():NextInteger(1, count)]
end

function WalkToRandomPost.connectDiedConnection(self: WalkToRandomPost, agent: Agent): ()
	if not self.diedConnection then
		local humanoid = agent.character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self.diedConnection = humanoid.Died:Once(function()
				self:nullify(agent)
			end)
		end
	end

	if not self.destroyedConnection then
		self.destroyedConnection = agent.character.Destroying:Once(function()
			self:nullify(agent)
		end)
	end
end

function WalkToRandomPost.nullify(self: WalkToRandomPost, agent: Agent): ()
	local targetPost = agent:getBrain():getMemory(MemoryModuleTypes.TARGET_POST)
	if targetPost:isPresent() then
		targetPost:get():vacate()
	end

	if agent:getBrain():getMemory(MemoryModuleTypes.PATROL_STATE):get() == PatrolState.WALKING then
		if self.previousPost then
			self.previousPost:vacate()
		end
	end

	local currentPost = agent:getBrain():getMemory(MemoryModuleTypes.CURRENT_POST)
	if currentPost:isPresent() then
		currentPost:get():vacate()
		agent:getBrain():eraseMemory(MemoryModuleTypes.CURRENT_POST)
	end
end

return WalkToRandomPost