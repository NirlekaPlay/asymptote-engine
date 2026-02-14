--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local AttentionLevel = require(ServerScriptService.server.ai.behavior.attention.AttentionLevel)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

local DEFAULT_ATTENTION_LEVEL = AttentionLevel.CALM
local ATTENTION_BLINK_SETTINGS = {
	[AttentionLevel.CALM] = {min = 3, max = 6, blinkDur = 0.25},
	[AttentionLevel.ALERT] = {min = 10, max = 15, blinkDur = 0.08},
	[AttentionLevel.ADRENALINE] = {min = 1, max = 3, blinkDur = 007}
}

--[=[
	@class BlinkEyes
]=]
local BlinkEyes = {}
BlinkEyes.__index = BlinkEyes
BlinkEyes.ClassName = "BlinkEyes"

export type BlinkEyes = typeof(setmetatable({} :: {
	_timeToNextBlink: number,
	_isBlinking: boolean,
	_blinkTimer: number,
}, BlinkEyes))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function BlinkEyes.new(): BlinkEyes
	return setmetatable({
		_timeToNextBlink = 5,
		_isBlinking = false,
		_blinkTimer = 0,
	}, BlinkEyes)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.ATTENTION_LEVEL] = MemoryStatus.REGISTERED
}

function BlinkEyes.getMemoryRequirements(self: BlinkEyes): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function BlinkEyes.checkExtraStartConditions(self: BlinkEyes, agent: Agent): boolean
	return true
end

function BlinkEyes.canStillUse(self: BlinkEyes, agent: Agent): boolean
	return true
end

function BlinkEyes.doStart(self: BlinkEyes, agent: Agent): ()
	return
end

function BlinkEyes.doStop(self: BlinkEyes, agent: Agent): ()
	return
end

function BlinkEyes.doUpdate(self: BlinkEyes, agent: Agent, deltaTime: number): ()
	local faceControl = agent:getFaceControl()
	local attentionLevel = agent:getBrain():getMemory(MemoryModuleTypes.ATTENTION_LEVEL):orElse(DEFAULT_ATTENTION_LEVEL)
	local currentBlinkDur = ATTENTION_BLINK_SETTINGS[attentionLevel].blinkDur

	if self._isBlinking then
		self._blinkTimer += deltaTime
		if self._blinkTimer >= currentBlinkDur then
			self._isBlinking = false
			self._blinkTimer = 0
			faceControl:setEyesAlias("Open")
		end
		return
	end

	self._timeToNextBlink -= deltaTime

	if self._timeToNextBlink <= 0 then
		self._isBlinking = true
		faceControl:setEyesAlias("Closed")

		local rate = ATTENTION_BLINK_SETTINGS[attentionLevel] or ATTENTION_BLINK_SETTINGS[DEFAULT_ATTENTION_LEVEL]
		self._timeToNextBlink = math.random(rate.min, rate.max)
	end
end

return BlinkEyes