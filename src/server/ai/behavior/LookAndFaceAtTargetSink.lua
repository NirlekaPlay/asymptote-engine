--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local Behavior = require(ServerScriptService.server.ai.behavior.Behavior)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

local LookAndFaceAtTargetSink = {}
LookAndFaceAtTargetSink.__index = LookAndFaceAtTargetSink
setmetatable(LookAndFaceAtTargetSink, { __index = Behavior })

function LookAndFaceAtTargetSink.new()
	local self = Behavior.new({
		[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.VALUE_PRESENT
	})
	setmetatable(self, LookAndFaceAtTargetSink)
	return self
end

export type LookAndFaceAtTargetSink = typeof(LookAndFaceAtTargetSink.new())

function LookAndFaceAtTargetSink.canStillUse(self: LookAndFaceAtTargetSink, agent: Agent.Agent): boolean
	local brain = agent:getBrain()
	return brain:getMemory(MemoryModuleTypes.LOOK_TARGET):filter(function(targetPlayer)
		local visiblePlayers = brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
		if visiblePlayers:isPresent() then
			return visiblePlayers:get():getValue()[targetPlayer:getValue()] ~= nil
		end

		return false
	end):isPresent()
end

function LookAndFaceAtTargetSink.doStop(self: LookAndFaceAtTargetSink, agent: Agent.Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
end

function LookAndFaceAtTargetSink.doUpdate(self: LookAndFaceAtTargetSink, agent: Agent.Agent): ()
	local lookTarget = agent:getBrain():getMemory(MemoryModuleTypes.LOOK_TARGET)
	if lookTarget:isPresent() then
		local charPos = lookTarget:get():getValue().Character.PrimaryPart.Position
		agent:getBodyRotationControl():setRotateTowards(charPos)
		agent:getLookControl():setLookAtPos(charPos)
	end
end

return LookAndFaceAtTargetSink