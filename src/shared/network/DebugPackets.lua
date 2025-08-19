--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BrainDebugPayload = require(script.Parent.BrainDebugPayload)
local TypedRemotes = require(script.Parent.TypedRemotes)
local Agent = require(ServerScriptService.server.Agent)

local PACKETS = {
	DEBUG_BRAIN = "DEBUG_BRAIN"
}

local activeClientListeners: { [string]: { [Player]: true } } = {}

TypedRemotes.SubscribeDebugDump.OnServerEvent:Connect(function(player, debugName, subscribe)
	if not activeClientListeners[debugName] then
		activeClientListeners[debugName] = {}
	end

	local value = if subscribe then true else nil
	activeClientListeners[debugName][player] = value
end)

--[=[
	@class DebugPackets
]=]
local DebugPackets = {}

local function isArray(t)
	if type(t) ~= "table" then
		return false
	end

	local count = 0
	for k, _ in pairs(t) do
		if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
			return false
		end
		if k > count then
			count = k
		end
	end

	for i = 1, count do
		if t[i] == nil then
			return false
		end
	end

	return true
end

function DebugPackets.sendBrainDumpToListeningClients(agent: Agent.Agent): ()
	if not activeClientListeners[PACKETS.DEBUG_BRAIN] then
		activeClientListeners[PACKETS.DEBUG_BRAIN] = {}
		return
	end

	if next(activeClientListeners[PACKETS.DEBUG_BRAIN]) == nil then
		return
	end

	for player in pairs(activeClientListeners[PACKETS.DEBUG_BRAIN]) do
		local brainDump = DebugPackets.createBrainDump(agent)
		TypedRemotes.BrainDebugDump:FireClient(player, brainDump)
	end
end

function DebugPackets.createBrainDump(agent: Agent.Agent): BrainDebugPayload.BrainDump
	local brain = agent:getBrain()
	local brainDump: BrainDebugPayload.BrainDump = {}

	brainDump.memories = DebugPackets.getMemoryDescriptions(agent)
	brainDump.activites = {}
	for activity, _ in pairs(brain.activeActivities) do
		brainDump.activites[activity.name] = true
	end
	brainDump.behaviors = {}
	for _, behaviorControl in ipairs(brain:getRunningBehaviors()) do
		brainDump.behaviors[behaviorControl.name] = true
	end
	brainDump.character = agent.character
	brainDump.health = agent.character.Humanoid.Health
	brainDump.maxHealth = agent.character.Humanoid.MaxHealth
	brainDump.name = agent:getCharacterName()
	brainDump.uuid = agent:getUuid()

	return brainDump
end

--

function DebugPackets.getMemoryDescriptions(agent: Agent.Agent): { string }
	local memories = agent:getBrain().memories
	local array: { string } = {}

	for memoryModuleType, optional in pairs(memories) do
		local s: string

		if optional:isPresent() then
			local expireableValue = optional:get()
			local object = expireableValue:getValue()
			if expireableValue:canExpire() then
				s = DebugPackets.getShortDescription(object) .. " (ttl: " .. expireableValue:getTimeToLive() .. ")"
			else
				s = DebugPackets.getShortDescription(object)
			end
		else
			s = "-"
		end

		table.insert(array, memoryModuleType.name .. ": " .. s)
	end

	table.sort(array)
	return array
end

function DebugPackets.getShortDescription<T>(value: T?): string
	if value == nil then
		return "-"
	elseif typeof(value) == "Vector3" then
		return `Vector3\{x={value.X}, y={value.Y}, z={value.Z}\}`
	elseif typeof(value) == "Instance" then
		return tostring(value)
	elseif type(value) == "table" then
		local mt = getmetatable(value :: any)
		if mt and mt.__tostring then
			return tostring(value)
		else
			return DebugPackets.getTableShortDescription(value)
		end
	else
		return tostring(value)
	end
end

function DebugPackets.getTableShortDescription(t: { any } | { [any]: any }): string
	if isArray(t) then
		local length = #t
		local result = table.create(length, true) :: { string }

		for i = 1, length do
			result[i] = DebugPackets.getShortDescription(t[i])
		end

		return "[ " .. table.concat(result, ", ") .. " ]"
	else
		local parts = {}

		for k, v in pairs(t) do
			local keyStr
			if type(k) == "string" then
				keyStr = string.format("%q", k) -- quoted string
			else
				keyStr = DebugPackets.getShortDescription(k)
			end

			local valueStr
			if type(v) == "string" then
				valueStr = string.format("%q", v)
			else
				valueStr = DebugPackets.getShortDescription(v)
			end

			table.insert(parts, string.format("[ %s ]: %s", keyStr, valueStr))
		end

		return "{ " .. table.concat(parts, ", ") .. " }"
	end
end

return DebugPackets