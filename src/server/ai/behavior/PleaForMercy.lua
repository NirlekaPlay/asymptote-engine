--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class PleaForMercy
]=]
local PleaForMercy = {}
PleaForMercy.__index = PleaForMercy
PleaForMercy.ClassName = "PleaForMercy"

export type PleaForMercy = typeof(setmetatable({} :: {
	alreadyRun: boolean
}, PleaForMercy))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent

function PleaForMercy.new(): PleaForMercy
	return setmetatable({
		minDuration = 1,
		maxDuration = 1,
		alreadyRun = false
	}, PleaForMercy)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT
	--[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_PRESENT
}

function PleaForMercy.getMemoryRequirements(self: PleaForMercy): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function PleaForMercy.checkExtraStartConditions(self: PleaForMercy, agent: Agent): boolean
	return not self.alreadyRun
end

function PleaForMercy.canStillUse(self: PleaForMercy, agent: Agent): boolean
	return false
end

function PleaForMercy.doStart(self: PleaForMercy, agent: Agent): ()
	self.alreadyRun = true
	local player = agent:getBrain():getMemory(MemoryModuleTypes.PANIC_PLAYER_SOURCE):get():getValue()
	local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
	if not playerStatus then
		return
	end

	local highestStatus = playerStatus:getHighestPriorityStatus()
	if highestStatus then
		if highestStatus == "ARMED" then
			if agent:canBeIntimidated() then
				agent:getTalkControl():sayRandomSequences(
					{
						{"Wait wait wait!", "Don't shoot!!!"},
						{"Holy shrimp!", "You have a gun?!", "Do you even have a license for that?!"},
						{"Awh holly Envvy!", "Okay okay!", "Please! I have a family!"}
					}
				)
			else
				agent:getTalkControl():sayRandomSequences(
					{
						{"Oh crap! He's got a gun!", "Open fire!!"},
						{"Control! We got a shooter here!"},
						{"There's someone with a gun!", "Envvy save us!!!"}
					}
				)
			end
		elseif highestStatus == "DANGEROUS_ITEM" then
			if agent:canBeIntimidated() then
				agent:getTalkControl():sayRandomSequences(
					{
						{"Whoa whoa whoa!", "Is that...", "is that a bomb?!", "Why would you even bring that here?!"},
						{"Okay okay!", "Please put it down!", "I—I bruise easily!"},
						{"Oh no no no!", "I didn't sign up for this!", "I just wanted a normal day at work!"},
						{"Are you gonna use that..!", "Just to see me ragdoll?!", "This is absurd!"}
					}
				)
			else
				agent:getTalkControl():sayRandomSequences(
					{
						{"Control!! Someone here has a bomb!!"},
						{"Control!!! Someone here is carrying a bomb!!"},
						{"Agh!", "He's got a bomb!"},
						{"Agh shrimp!", "Thats an armed bomb!"}
					}
				)
			end
		end
	end
end

function PleaForMercy.doStop(self: PleaForMercy, agent: Agent): ()
	return
end

function PleaForMercy.doUpdate(self: PleaForMercy, agent: Agent, deltaTime: number): ()
	return
end

return PleaForMercy