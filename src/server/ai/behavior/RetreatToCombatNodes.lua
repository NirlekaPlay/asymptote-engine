--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local Level = require(ServerScriptService.server.world.level.Level)

--[=[
	@class RetreatToCombatNodes
]=]
local RetreatToCombatNodes = {}
RetreatToCombatNodes.__index = RetreatToCombatNodes
RetreatToCombatNodes.ClassName = "RetreatToCombatNodes"

export type RetreatToCombatNodes = typeof(setmetatable({} :: {
	choosenNode: Node.Node?,
	currentComputationThread: thread?,
	humanoidDiedConnection: RBXScriptConnection?
}, RetreatToCombatNodes))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function RetreatToCombatNodes.new(): RetreatToCombatNodes
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		choosenNode = nil :: Node.Node?,
		currentComputationThread = nil :: thread?,
		humanoidDiedConnection = nil :: RBXScriptConnection?
	}, RetreatToCombatNodes)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.HAS_RETREATED] = MemoryStatus.VALUE_ABSENT
}

function RetreatToCombatNodes.getMemoryRequirements(self: RetreatToCombatNodes): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function RetreatToCombatNodes.checkExtraStartConditions(self: RetreatToCombatNodes, agent: Agent): boolean
	return true
end

function RetreatToCombatNodes.canStillUse(self: RetreatToCombatNodes, agent: Agent): boolean
	return self.choosenNode ~= nil and not agent:getBrain():hasMemoryValue(MemoryModuleTypes.HAS_RETREATED)
end

function RetreatToCombatNodes.doStart(self: RetreatToCombatNodes, agent: Agent): ()
	if self.choosenNode or self.currentComputationThread then
		return
	end

	-- I don't know who the fuck at Roblox thought computing a fucking path
	-- should yield and be asynchronous.
	print(`Starting to compute nearest node for '{agent:getCharacterName()}'...`)
	self.currentComputationThread = task.spawn(function()
		local nearestUnoccupiedPost = self:getNearestUnoccupiedCombatNode(agent)
		if nearestUnoccupiedPost then
			self.choosenNode = nearestUnoccupiedPost
			self:retreatToNode(nearestUnoccupiedPost, agent)
			self:connectDiedConnection(agent, nearestUnoccupiedPost)
			print(`Node computed successfully for '{agent:getCharacterName()}'!`)
		end
	end)
end

function RetreatToCombatNodes.doStop(self: RetreatToCombatNodes, agent: Agent): ()
	return
end

function RetreatToCombatNodes.doUpdate(self: RetreatToCombatNodes, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local nav = agent:getNavigation()
	local rot = agent:getBodyRotationControl()
	local hasRetreated = brain:hasMemoryValue(MemoryModuleTypes.HAS_RETREATED)

	if not hasRetreated then
		if nav.finished then
			nav.finished = false

			brain:setNullableMemory(MemoryModuleTypes.HAS_RETREATED, true)
			brain:eraseMemory(MemoryModuleTypes.LOOK_TARGET)
			rot:setRotateToDirection((self.choosenNode :: Node.Node).cframe.LookVector)
		end
	end
end

--

function RetreatToCombatNodes.connectDiedConnection(self: RetreatToCombatNodes, agent: Agent, occupiedNode: Node.Node?): ()
	if self.humanoidDiedConnection then
		self.humanoidDiedConnection:Disconnect()
		self.humanoidDiedConnection = nil
	end

	local humanoid = agent.character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.humanoidDiedConnection = humanoid.Died:Once(function()
			if self.currentComputationThread then
				task.cancel(self.currentComputationThread)
			end
			if occupiedNode and occupiedNode:isOccupied() then
				occupiedNode:vacate()
			end
			if self.humanoidDiedConnection then
				self.humanoidDiedConnection:Disconnect()
				self.humanoidDiedConnection = nil
			end
		end)
	end
end

function RetreatToCombatNodes.retreatToNode(self: RetreatToCombatNodes, node: Node.Node, agent: Agent): ()
	node:occupy()
	agent:getNavigation():moveTo(node.cframe.Position)
end

function RetreatToCombatNodes.getNearestUnoccupiedCombatNode(self: RetreatToCombatNodes, agent: Agent): Node.Node?
	local combatNodes = Level.getGuardCombatNodes()
	local nearestNode = nil
	local nearestDistance = math.huge  -- start with infinity

	for _, node in combatNodes do
		if node:isOccupied() then
			continue
		end

		local nodePos = node.cframe.Position
		local path = agent:getNavigation():generatePath(nodePos)
		if not path then
			continue
		end

		local distance = RetreatToCombatNodes.getWaypointsPathLength(path:GetWaypoints())

		if distance < nearestDistance then
			nearestDistance = distance
			nearestNode = node
		end
	end

	return nearestNode
end

function RetreatToCombatNodes.getWaypointsPathLength(waypoints: {PathWaypoint}): number
	local pathCost = 0
	for i = 2, #waypoints do
		pathCost = pathCost + (waypoints[i].Position - waypoints[i-1].Position).Magnitude
	end
	return pathCost
end

return RetreatToCombatNodes