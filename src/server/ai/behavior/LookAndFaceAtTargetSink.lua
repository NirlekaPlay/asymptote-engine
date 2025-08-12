--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

local LookAndFaceAtTargetSink = {}
LookAndFaceAtTargetSink.__index = LookAndFaceAtTargetSink
LookAndFaceAtTargetSink.ClassName = "LookAndFaceAtTargetSink"

export type LookAndFaceAtTargetSink = typeof(setmetatable({} :: {
}, LookAndFaceAtTargetSink))

function LookAndFaceAtTargetSink.new(): LookAndFaceAtTargetSink
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, LookAndFaceAtTargetSink)
end

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.LOOK_TARGET] = MemoryStatus.VALUE_PRESENT
}

function LookAndFaceAtTargetSink.getMemoryRequirements(self: LookAndFaceAtTargetSink): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function LookAndFaceAtTargetSink.checkExtraStartConditions(self: LookAndFaceAtTargetSink, agent: Agent): boolean
	return true
end

function LookAndFaceAtTargetSink.canStillUse(self: LookAndFaceAtTargetSink, agent: Agent.Agent): boolean
	local brain = agent:getBrain()
	local lookTarget = brain:getMemory(MemoryModuleTypes.LOOK_TARGET)
		:map(function(expValue)
			return expValue:getValue()
		end)

	-- do you understand what i did here? because i dont.
	-- yet it works so im not touching it.
	return lookTarget
		:flatMap(function(targetPlayer)
			return brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
				:map(function(visible)
					return visible:getValue()[targetPlayer]
			end)
		end)
		:isPresent() or lookTarget
		:flatMap(function(targetPlayer)
				return brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS)
					:map(function(visible)
						return visible:getValue()[targetPlayer]
			end)
		end)
		:isPresent()

		-- shit, flatMaps exist? mindblowing.
end


function LookAndFaceAtTargetSink.doStart(self: LookAndFaceAtTargetSink, agent: Agent): ()
	return
end

function LookAndFaceAtTargetSink.doStop(self: LookAndFaceAtTargetSink, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
	agent:getBodyRotationControl():setRotateTowards(nil)
	agent:getLookControl():setLookAtPos(nil)
end

function LookAndFaceAtTargetSink.doUpdate(self: LookAndFaceAtTargetSink, agent: Agent, deltaTime: number): ()
	local lookTarget = agent:getBrain():getMemory(MemoryModuleTypes.LOOK_TARGET)
	if lookTarget:isPresent() then
		local charPos = lookTarget:get():getValue().Character.PrimaryPart.Position
		agent:getBodyRotationControl():setRotateTowards(charPos)
		agent:getLookControl():setLookAtPos(charPos)
	end
end

return LookAndFaceAtTargetSink