--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Behaviour = require(script.Parent.Behaviour)
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local SetLookAtSusiciousPlayer = {}
SetLookAtSusiciousPlayer.__index = SetLookAtSusiciousPlayer

export type SetLookAtSusiciousPlayer = typeof(setmetatable({} :: {
	status: Behaviour.Status
}, SetLookAtSusiciousPlayer))

function SetLookAtSusiciousPlayer.new(): SetLookAtSusiciousPlayer
	return setmetatable({
		status = Behaviour.STOPPED :: Behaviour.Status
	}, SetLookAtSusiciousPlayer)
end

function SetLookAtSusiciousPlayer.getStatus(self: SetLookAtSusiciousPlayer, ...)
	return self.status
end

function SetLookAtSusiciousPlayer.tryStart(self: SetLookAtSusiciousPlayer, agent: Agent.Agent): ()
	local susMan = agent:getSuspicionManager()
	local focusingTarget = susMan:getFocusingTarget()
	if focusingTarget and susMan:isCurious() then
		agent:getBrain():setNullableMemory(MemoryModuleTypes.LOOK_TARGET, focusingTarget)
	else
		agent:getBrain():setNullableMemory(MemoryModuleTypes.LOOK_TARGET, nil)
	end
end

function SetLookAtSusiciousPlayer.updateOrStop(self: SetLookAtSusiciousPlayer, ...): ()
	return
end

function SetLookAtSusiciousPlayer.doStop(self: SetLookAtSusiciousPlayer, agent: Agent.Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.LOOK_TARGET)
end

return SetLookAtSusiciousPlayer