--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local DummySensor = {}
DummySensor.__index = DummySensor

export type DummySensor = typeof(setmetatable({} :: {
}, DummySensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent -- the agent type idk

function DummySensor.new(): DummySensor
	return setmetatable({
		rayParams = nil :: RaycastParams?
	}, DummySensor)
end

function DummySensor.getRequiredMemories(self: DummySensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return {} -- return all required memories you need
end

function DummySensor.getScanRate(self: DummySensor): number
	return 1/20 -- scan rate in seconds
end

function DummySensor.doUpdate(self: DummySensor, agent: Agent, deltaTime: number)
	-- actual logic here
	-- just type "agent" and you will see all of the numerous methods and properties
end

return DummySensor