--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Behaviour = require(script.Parent.Behaviour)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local LookAndFaceAtTarget = {}
LookAndFaceAtTarget.__index = LookAndFaceAtTarget

export type LookAndFaceAtTarget = typeof(setmetatable({} :: {
	status: Behaviour.Status
}, LookAndFaceAtTarget))

function LookAndFaceAtTarget.new(): LookAndFaceAtTarget
	return setmetatable({
		status = Behaviour.STOPPED :: Behaviour.Status
	}, LookAndFaceAtTarget)
end

function LookAndFaceAtTarget.getStatus(self: LookAndFaceAtTarget, ...)
	return self.status
end

function LookAndFaceAtTarget.tryStart(self: LookAndFaceAtTarget, ...): ()
	self.status = "RUNNING"
end

function LookAndFaceAtTarget.updateOrStop(self: LookAndFaceAtTarget, agent: Agent.Agent): ()
	local nearestPlayerMemory = agent:getBrain():getMemory(MemoryModuleTypes.LOOK_TARGET)
	if nearestPlayerMemory:isPresent() then
		local player = nearestPlayerMemory:get():getValue()
		if not player.Character then return end
		local playerPos = player.Character.PrimaryPart.Position

		agent:getLookControl():setLookAtPos(playerPos)
		agent:getBodyRotationControl():setRotateTowards(playerPos)
	else
		agent:getLookControl():setLookAtPos(nil)
		agent:getBodyRotationControl():setRotateTowards(nil)
	end
end

function LookAndFaceAtTarget.doStop(self: LookAndFaceAtTarget, ...): ()
	self.status = "STOPPED"
end

return LookAndFaceAtTarget