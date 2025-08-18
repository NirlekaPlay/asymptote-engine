--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class FollowPlayerSink
]=]
local FollowPlayerSink = {}
FollowPlayerSink.__index = FollowPlayerSink
FollowPlayerSink.ClassName = "FollowPlayerSink"

export type FollowPlayerSink = typeof(setmetatable({} :: {
	waypointReachedConnection: RBXScriptConnection?,
	following: boolean
}, FollowPlayerSink))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function FollowPlayerSink.new(): FollowPlayerSink
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge
	}, FollowPlayerSink)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.FOLLOW_TARGET] = MemoryStatus.VALUE_PRESENT
}

local FOLLOW_START_DISTANCE = 15 -- distance at which following begins
local FOLLOW_STOP_DISTANCE = 7 -- distance at which following ends

function FollowPlayerSink.getMemoryRequirements(self: FollowPlayerSink): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function FollowPlayerSink.checkExtraStartConditions(self: FollowPlayerSink, agent: Agent): boolean
	if not agent:getBrain():hasMemoryValue(MemoryModuleTypes.FOLLOW_TARGET) then
		return false
	end

	local followTarget = agent:getBrain():getMemory(MemoryModuleTypes.FOLLOW_TARGET):get():getValue()
	if not followTarget.Character then
		return false
	end

	local followTargetPrimaryPart = followTarget.Character.PrimaryPart :: BasePart
	local agentPrimaryPart = agent:getPrimaryPart()
	local distance = (followTargetPrimaryPart.Position - agentPrimaryPart.Position).Magnitude

	if distance > FOLLOW_START_DISTANCE then
		return true
	end

	if distance < FOLLOW_STOP_DISTANCE then
		return false
	end

	return self:isFollowing()
end

function FollowPlayerSink.canStillUse(self: FollowPlayerSink, agent: Agent): boolean
	return self:checkExtraStartConditions(agent)
end

function FollowPlayerSink.doStart(self: FollowPlayerSink, agent: Agent): ()
	local followTarget = agent:getBrain():getMemory(MemoryModuleTypes.FOLLOW_TARGET):get():getValue()
	local followTargetPrimaryPart = followTarget.Character.PrimaryPart :: BasePart

	self.following = true
	agent:getNavigation():moveTo(followTargetPrimaryPart.Position)
end

function FollowPlayerSink.doStop(self: FollowPlayerSink, agent: Agent): ()
	self.following = false
	agent:getNavigation():stop()
end

function FollowPlayerSink.doUpdate(self: FollowPlayerSink, agent: Agent, deltaTime: number): ()
	return
end

--

function FollowPlayerSink.isFollowing(self: FollowPlayerSink): boolean
	return self.following
end

function FollowPlayerSink.onWaypointReached(self: FollowPlayerSink, agent: Agent): ()
	
end

return FollowPlayerSink