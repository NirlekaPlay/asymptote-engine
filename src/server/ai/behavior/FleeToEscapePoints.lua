--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

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
		minDuration = 5,
		maxDuration = 5
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
	warn(post)
	agent.character.Humanoid.WalkSpeed = 19
	agent:getNavigation():moveTo(post.cframe.Position)
end

function FleeToEscapePoints.doStop(self: FleeToEscapePoints, agent: Agent): ()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.HAS_FLED, true)
	agent:getBodyRotationControl():setRotateToDirection(agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get():getValue())
	agent:getNavigation():stop()
end

function FleeToEscapePoints.doUpdate(self: FleeToEscapePoints, agent: Agent, deltaTime: number): ()
	return
end

--

function FleeToEscapePoints.getPostWithMinimumDistanceFromPanicPos(self: FleeToEscapePoints, agent: Agent): GuardPost.GuardPost?
	local posts = agent:getBrain():getMemory(MemoryModuleTypes.DESIGNATED_POSTS):get():getValue()
	local panicPos = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_POSITION):get():getValue()
	local totalPosts = #posts
	local currentPost = agent:getBrain():getMemory(MemoryModuleTypes.TARGET_POST):ifPresent(function(expValue)
		return expValue:getValue()
	end)

	for i, post in ipairs(posts) do
		if post == currentPost then
			print("its current post, skip")
			continue
		end
		-- TODO: This is dumb. We need to make it so that it runs to the correct direction
		-- from the panic position.
		local distance = (panicPos - agent:getPrimaryPart().Position).Magnitude
		if distance >= MIN_DISTANCE_FROM_PANIC_POS or i == totalPosts then
			print("distance:", distance)
			return post
		end
	end

	return nil
end

return FleeToEscapePoints