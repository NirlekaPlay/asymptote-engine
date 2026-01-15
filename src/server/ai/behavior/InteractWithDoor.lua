--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Bounds = require(ReplicatedStorage.shared.math.geometry.Bounds)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local Level = require(ServerScriptService.server.world.level.Level)
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)

--[=[
	@class InteractWithDoor
]=]
local InteractWithDoor = {}
InteractWithDoor.__index = InteractWithDoor
InteractWithDoor.ClassName = "InteractWithDoor"

export type InteractWithDoor = typeof(setmetatable({} :: {
	sanityInduceThread: thread?
}, InteractWithDoor))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function InteractWithDoor.new(): InteractWithDoor
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?,
		sanityInduceThread = nil :: thread?
	}, InteractWithDoor)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.PATH] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.WALK_TARGET] = MemoryStatus.VALUE_PRESENT
}

function InteractWithDoor.getMemoryRequirements(self: InteractWithDoor): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function InteractWithDoor.checkExtraStartConditions(self: InteractWithDoor, agent: Agent): boolean
	local isPathDone = agent:getBrain():getMemory(MemoryModuleTypes.PATH):get():isDone()
	if isPathDone then
		return false
	end

	return true
end

function InteractWithDoor.canStillUse(self: InteractWithDoor, agent: Agent): boolean
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.PATH)
		and not agent:getBrain():getMemory(MemoryModuleTypes.PATH):get():isDone()
end

function InteractWithDoor.doStart(self: InteractWithDoor, agent: Agent): ()
	return
end

function InteractWithDoor.doStop(self: InteractWithDoor, agent: Agent): ()
	return
end

function InteractWithDoor.doUpdate(self: InteractWithDoor, agent: Agent, deltaTime: number): ()
	local path = agent:getBrain():getMemory(MemoryModuleTypes.PATH):get()
	local nextNode = path:getNextNode()
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { agent.character }

	local partsInRadius = workspace:GetPartBoundsInRadius(nextNode.Position, 4, overlapParams)
	local agentPos = (agent.character.HumanoidRootPart :: BasePart).Position

	-- Performance?
	-- Hah, whats that?
	-- If it works it works.

	-- TODO: Do the thing.

	-- O(*sodding terrible*)
	for _, part in partsInRadius do
		if part.Name == "DoorBounds" then
			--[[if (part.Position - agentPos).Magnitude > 4 then
				continue
			end]]

			local found = false
			for i = path:getNextNodeIndex(), path:getWaypointCount() do
				local node = path:getNode(i)
				local isInDoorBounds = Bounds.isPosInPart(node.Position, part)

				if isInDoorBounds then
					found = true
					break
				end
			end

			if found then
				-- What the fuck.
				local propsInLevel = Level.getProps()
				for prop in propsInLevel do
					if getmetatable(prop) == Door and (prop :: Door.Door).doorPathReqPart == part then
						local door = prop :: Door.Door
						if door:isClosed() or door.state == Door.States.CLOSING then
							local basePos = part.Position
							local forwardDir = door:getForwardDir()
							local origin = basePos
							local toTarget = (agentPos - origin)
							local dotResult = forwardDir:Dot(toTarget)
							local openingSide

							if dotResult > 0 then
								-- Agent is infront of the door
								openingSide = Door.Sides.FRONT
							elseif dotResult < 0 then
								-- Agent is behind
								openingSide = Door.Sides.BACK
							else
								-- Exactly perpendicular, just put it to front
								openingSide = Door.Sides.FRONT
							end
							door:onPromptTriggered(openingSide)

							-- Sigh.
							if not self.sanityInduceThread then
								self.sanityInduceThread = task.delay(2, function()
									local shouldClose = true
									if not part then
										self.sanityInduceThread = nil
										print("Return sanity thread")
										return
									end

									if door:isClosed() then
										self.sanityInduceThread = nil
										return
									end

									local queried = workspace:GetPartBoundsInRadius(part.Position, 2, overlapParams)
									for _, queriedPart in queried do
										if not queriedPart.Parent then
											continue
										end

										if not queriedPart:IsA("Model") then
											continue
										end

										if (queriedPart :: Model):FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(queriedPart.Parent) then
											shouldClose = false
											break
										end
									end

									if shouldClose then
										door:onPromptTriggered(Door.Sides.MIDDLE)
									end
									self.sanityInduceThread = nil
								end)
							end
							
							break
						end
					end
				end
			end
		end
	end
end

return InteractWithDoor