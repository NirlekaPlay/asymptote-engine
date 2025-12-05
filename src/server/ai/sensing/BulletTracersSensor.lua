--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)

local DEBUG_RADIUS = false
local DEBUG_BULLET_INIT_DIRS = false

local BulletTracersSensor = {}
BulletTracersSensor.__index = BulletTracersSensor

export type BulletTracersSensor = typeof(setmetatable({} :: {
	detectionRadius: number,
	debugDetectionRadiusPart: BasePart?
}, BulletTracersSensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent -- the agent type idk

local SCAN_RATE = 1 / 20 -- scan rate in seconds

function BulletTracersSensor.new(detectionRadius: number): BulletTracersSensor
	return setmetatable({
		rayParams = nil :: RaycastParams?,
		detectionRadius = detectionRadius,
		debugDetectionRadiusPart = DEBUG_RADIUS and Draw.sphere(Vector3.zero, detectionRadius) or nil
	}, BulletTracersSensor)
end

function BulletTracersSensor.getRequiredMemories(self: BulletTracersSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return {
		MemoryModuleTypes.VISIBLE_ENTITIES
	}
end

function BulletTracersSensor.getScanRate(self: BulletTracersSensor): number
	return SCAN_RATE
end

local function rayIntersectsSphere(rayOrigin: Vector3, rayDirection: Vector3, sphereCenter: Vector3, sphereRadius: number): (boolean, number)
	local L = rayOrigin - sphereCenter
	local b = 2 * L:Dot(rayDirection)

	local c = L:Dot(L) - (sphereRadius * sphereRadius)

	local discriminant = (b * b) - (4 * c)

	if discriminant < 0 then
		return false, 0
	end

	local sqrtDiscriminant = math.sqrt(discriminant)

	-- t1 and t2 are the two solutions for the quadratic equation
	local t1 = (-b - sqrtDiscriminant) / 2 -- t1 will be the smaller (closer) value
	local t2 = (-b + sqrtDiscriminant) / 2 -- t2 will be the larger (further) value

	if t1 < 0 then
		if t2 >= 0 then
			return true, t2
		else
			return false, 0
		end
	end

	return true, t1
end

function BulletTracersSensor.doUpdate(self: BulletTracersSensor, agent: Agent, deltaTime: number): ()
	local agentPrimaryPartPos = agent:getPrimaryPart().Position
	local detectionRadius = self.detectionRadius
	local bullets = BulletSimulation.getBulletsInitialCFrames()
	if DEBUG_RADIUS and self.debugDetectionRadiusPart then
		(self.debugDetectionRadiusPart :: BasePart).Position = agentPrimaryPartPos
	end

	for bulletObj, initialCFrame in bullets do
		local rayOrigin = initialCFrame.Position
		local rayDirection = initialCFrame.LookVector

		if DEBUG_BULLET_INIT_DIRS then
			Debris:AddItem(Draw.direction(rayOrigin, rayDirection), 0.5)
		end

		local isHit, t = rayIntersectsSphere(rayOrigin, rayDirection, agentPrimaryPartPos, detectionRadius)
		if isHit and t < 1000 then
			warn("Bullet intersected the agent at distance: " .. t)
		end
	end
end

return BulletTracersSensor