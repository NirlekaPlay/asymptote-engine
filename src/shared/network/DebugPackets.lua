--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local ServerScriptService = game:GetService("ServerScriptService")

local DebugEntityNameGenerator = require(ReplicatedStorage.shared.network.DebugEntityNameGenerator)
local DebugPacketTypes = require(ReplicatedStorage.shared.network.DebugPacketTypes)
local BrainDebugPayload = require(ReplicatedStorage.shared.network.payloads.BrainDebugPayload)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
--local Agent = require(ServerScriptService.server.Agent) -- Circular dependency motherfucking bullshit.

local PACKETS = DebugPacketTypes

local FORMAT_NUMBER_EPSILON = 1e-6

local activeClientListeners: { [string]: { [Player]: true } } = {}
local debugBatches: { [string]: { any } } = {}

--[=[
	@class DebugPackets
]=]
local DebugPackets = {}

local function isArray<K, V>(t: { [K]: V }): boolean
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

local function formatNumber(n: number): string
	if n == 0 then
		return "0" -- prevents stuff like '-0'
	elseif math.abs(n) < FORMAT_NUMBER_EPSILON then
		return "0.00"
	elseif n % 1 == 0 then
		return tostring(n)
	else
		return string.format("%.2f", n)
	end
end

local function tableOnlyHasOneEntry(t: { [any]: any }): boolean
	local count = 0
	for _, _ in pairs(t) do
		count += 1
		if count > 1 then
			return false
		end
	end

	return count > 0
end

--

function DebugPackets.sendDynamicDebugPayloadToClients(debugName: string, payload: any): ()
	TypedRemotes.ClientBoundDynamicDebugDump:FireAllClients(debugName, payload)
end

function DebugPackets.hasListeningClients(debugName: string): boolean
	if not activeClientListeners[debugName] then
		activeClientListeners[debugName] = {}
		return false
	end

	if next(activeClientListeners[debugName]) == nil then
		return false
	end

	return true
end

function DebugPackets.clearBatch(debugName: string): ()
	if not debugBatches[debugName] then
		return
	end

	table.clear(debugBatches[debugName])
end

function DebugPackets.queueDataToBatch(debugName: string, data: any): ()
	if not debugBatches[debugName] then
		debugBatches[debugName] = {}
	end

	table.insert(debugBatches[debugName], data)
end

function DebugPackets.flushBrainDumpsToListeningClients(): ()
	if next(activeClientListeners[PACKETS.DEBUG_BRAIN]) == nil then
		return
	end

	if next(debugBatches[PACKETS.DEBUG_BRAIN]) == nil then
		return
	end

	for player in pairs(activeClientListeners[PACKETS.DEBUG_BRAIN]) do
		TypedRemotes.BrainDebugDump:FireClient(player, debugBatches[PACKETS.DEBUG_BRAIN])
	end

	DebugPackets.clearBatch(PACKETS.DEBUG_BRAIN)
end

function DebugPackets.onReceiveSubscription(player: Player, debugName: string, subscribe: boolean): ()
	if not activeClientListeners[debugName] then
		activeClientListeners[debugName] = {}
	end

	local value = if subscribe then true else nil
	activeClientListeners[debugName][player] = value
end

function DebugPackets.createBrainDump(agent: Agent.Agent): BrainDebugPayload.BrainDump
	local brain = agent:getBrain()
	local humanoid = agent.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local brainDump = {} :: BrainDebugPayload.BrainDump 

	brainDump.memories = DebugPackets.getMemoryDescriptions(agent)
	brainDump.activites = {}
	brainDump.behaviors = {}
	brainDump.character = agent.character
	brainDump.health = humanoid.Health
	brainDump.maxHealth = humanoid.MaxHealth
	brainDump.name = DebugEntityNameGenerator.getEntityName(agent)
	brainDump.uuid = agent:getUuid()

	for activity, _ in pairs(brain.activeActivities) do
		table.insert(brainDump.activites, activity.name)
	end

	for _, behaviorControl in ipairs(brain:getRunningBehaviors()) do
		table.insert(brainDump.behaviors, behaviorControl.name)
	end

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

function DebugPackets.getShortDescription(value: any): string
	if value == nil then
		return "-"
	elseif type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) == "number" then
		return formatNumber(value)
	elseif typeof(value) == "Vector3" then
		return `Vector3\{x={formatNumber(value.X)}, y={formatNumber(value.Y)}, z={formatNumber(value.Z)}\}`
	elseif typeof(value) == "Instance" then
		return tostring(value)
	elseif type(value) == "table" then
		local mt = getmetatable(value :: any)
		if mt and mt.__tostring then
			return tostring(value)
		else
			return DebugPackets.getTableShortDescription(value :: { [any]: any })
		end
	else
		return tostring(value)
	end
end

function DebugPackets.getTableShortDescription<K, V>(t: { [K]: V }): string
	if isArray(t) then
		local length = #t
		local result = table.create(length, true) :: { string }

		for i = 1, length do
			result[i] = DebugPackets.getShortDescription(t[i])
		end

		return "[ " .. table.concat(result, ", ") .. " ]"
	else
		-- we represent enums like this.
		-- an example is MemoryStatus. But since we're using memories, see PatrolState.
		if tableOnlyHasOneEntry(t) and (t :: { name: string?})["name"] and type(t.name) == "string" then
			return t.name:upper()
		end

		local parts: { string } = {}

		for k, v in pairs(t) do
			table.insert(parts,
				string.format(
					"[ %s ]: %s",
					DebugPackets.getShortDescription(k),
					DebugPackets.getShortDescription(v)
				)
			)
		end

		return "{ " .. table.concat(parts, ", ") .. " }"
	end
end

--

return DebugPackets