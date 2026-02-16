--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Vec3 = require(ReplicatedStorage.shared.util.vector.Vec3)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local WalkTarget = require(ServerScriptService.server.ai.memory.WalkTarget)
local NodePath = require(ServerScriptService.server.world.level.pathfinding.NodePath)

local USE_DIST_MANHATTAN = false

local WalkToTargetSink = {}
WalkToTargetSink.__index = WalkToTargetSink
WalkToTargetSink.ClassName = "WalkToTargetSink"

export type WalkToTargetSink = typeof(setmetatable({} :: {
	remainingCooldown: number,
	lastTargetPos: Vector3?,
	timeSinceLastFrame: number,
	isComputing: boolean,
	currentPath: NodePath.NodePath?,
	speedModifier: number
}, WalkToTargetSink))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function WalkToTargetSink.new(): WalkToTargetSink
	return setmetatable({
		remainingCooldown = 0,
		lastTargetPos = nil :: Vector3?,
		timeSinceLastFrame = os.clock(),
		isComputing = false,
		currentPath = nil :: NodePath.NodePath?,
		speedModifier = 1
	}, WalkToTargetSink)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.PATH] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.WALK_TARGET] = MemoryStatus.VALUE_PRESENT,
}

function WalkToTargetSink.getMemoryRequirements(self: WalkToTargetSink): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function WalkToTargetSink.checkExtraStartConditions(self: WalkToTargetSink, agent: Agent): boolean
	local now = os.clock()
	local deltaTime = now - self.timeSinceLastFrame
	self.timeSinceLastFrame = now

	if self.remainingCooldown > 0 then
		self.remainingCooldown -= deltaTime
		return false
	end

	if self.isComputing then
		return false
	end

	local brain = agent:getBrain()
	local walkTarget = brain:getMemory(MemoryModuleTypes.WALK_TARGET):get()
	local hasReachedTarget = WalkToTargetSink.hasReachedTarget(agent, walkTarget)

	if not hasReachedTarget then
		local success = WalkToTargetSink.tryComputePath(self, agent, walkTarget)
		if success then
			self.lastTargetPos = walkTarget:getTarget():getCurrentPosition()
			return true
		end
	else
		brain:eraseMemory(MemoryModuleTypes.WALK_TARGET)
		brain:eraseMemory(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE)
	end

	return false
end

function WalkToTargetSink.canStillUse(self: WalkToTargetSink, agent: Agent): boolean
	if not self.currentPath or not self.lastTargetPos then
		return false
	end

	local brain = agent:getBrain()
	local walkTargetOpt = brain:getMemory(MemoryModuleTypes.WALK_TARGET)
	
	if not walkTargetOpt:isPresent() then
		return false
	end

	local walkTarget = walkTargetOpt:get()
	local reached = WalkToTargetSink.hasReachedTarget(agent, walkTarget)
	
	return not reached
end

function WalkToTargetSink.doStart(self: WalkToTargetSink, agent: Agent): ()
	agent:getBrain():setMemory(MemoryModuleTypes.PATH, self.currentPath)
	if self.currentPath then
		local waypoints = self.currentPath:getWaypoints()
		
		for i, waypoint in waypoints do
			local isDoor = agent:getNavigation():getPathfinder():getNodeEvaluator():isWaypointDoor(waypoint)
			local color = isDoor and Color3.fromRGB(255, 85, 0) or Color3.new(0, 0, 1)
			
			Debris:AddItem(Draw.point(waypoint.Position, color))
			if isDoor then
				Debris:AddItem(Draw.text(waypoint.Position, tostring(i), Color3.new(1,1,1)))
			end

			if i > 1 then
				local prevWaypoint = waypoints[i - 1]
				Debris:AddItem(Draw.line(prevWaypoint.Position, waypoint.Position, Color3.new(1, 1, 1)))
			end
		end
	end
	agent:getNavigation():moveToFromPath(self.currentPath, self.speedModifier)
end

function WalkToTargetSink.doStop(self: WalkToTargetSink, agent: Agent): ()
	agent:getNavigation():stop()
	agent:getBrain():eraseMemory(MemoryModuleTypes.WALK_TARGET)
	agent:getBrain():eraseMemory(MemoryModuleTypes.PATH)
	self.currentPath = nil
end

function WalkToTargetSink.doUpdate(self: WalkToTargetSink, agent: Agent, deltaTime: number): ()
	if self.isComputing then
		return
	end

	local brain = agent:getBrain()

	local path = agent:getNavigation():getPath()
	if self.currentPath ~= path then
		self.currentPath = path
		brain:setMemory(MemoryModuleTypes.PATH, self.currentPath)
	end

	local walkTargetOpt = brain:getMemory(MemoryModuleTypes.WALK_TARGET)

	if walkTargetOpt:isPresent() and self.lastTargetPos then
		local walkTarget = walkTargetOpt:get()
		local currentTargetPos = walkTarget:getTarget():getCurrentPosition()
		
		-- Recalculate if target position has shifted significantly
		if (currentTargetPos - self.lastTargetPos).Magnitude > 4.0 then
			task.spawn(function()
				local success = WalkToTargetSink.tryComputePath(self, agent, walkTarget)
				if success then
					self.lastTargetPos = currentTargetPos
					WalkToTargetSink.doStart(self, agent)
				end
			end)
		end
	end
end

function WalkToTargetSink.tryComputePath(self: WalkToTargetSink, agent: Agent, walkTarget: WalkTarget.WalkTarget): boolean
	local brain = agent:getBrain()
	local targetPos = walkTarget:getTarget():getCurrentPosition()

	self.isComputing = true
	
	local path = agent:getNavigation():createPathAsync(targetPos)

	self.isComputing = false
	self.currentPath = path
	self.speedModifier = walkTarget:getSpeedModifier()

	if path then
		brain:eraseMemory(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE)
		return true
	else
		if not brain:hasMemoryValue(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE) then
			brain:setMemory(MemoryModuleTypes.CANT_REACH_WALK_TARGET_SINCE, os.clock())
		end
		return false
	end
end

function WalkToTargetSink.hasReachedTarget(agent: Agent, walkTarget: WalkTarget.WalkTarget): boolean
	local closeEnoughDist = walkTarget:getCloseEnoughDist()
	local targetPos = walkTarget:getTarget():getBlockPosition()
	local npcPos = agent:getBlockPosition()
	if USE_DIST_MANHATTAN then
		return Vec3.distManhattan(targetPos, npcPos) <= closeEnoughDist
	else
		return (targetPos - npcPos).Magnitude <= closeEnoughDist
	end
end

return WalkToTargetSink