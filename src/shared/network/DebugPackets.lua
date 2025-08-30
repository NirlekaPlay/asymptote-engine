--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BrainDebugPayload = require(script.Parent.BrainDebugPayload)
local DebugEntityNameGenerator = require(script.Parent.DebugEntityNameGenerator)
local TypedRemotes = require(script.Parent.TypedRemotes)
local Agent = require(ServerScriptService.server.Agent)
local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)

local PACKETS = {
	DEBUG_BRAIN = "DEBUG_BRAIN"
}

local activeClientListeners: { [string]: { [Player]: true } } = {}
local debugBatches: { [string]: { any } } = {}

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
DebugPackets.Packets = PACKETS

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

function DebugPackets.hasListeningClients(debugName: string): boolean
	if not activeClientListeners[debugName] then
		activeClientListeners[debugName] = {}
		return false
	end

	if next(activeClientListeners[PACKETS.DEBUG_BRAIN]) == nil then
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

	DebugPackets.clearBatch(DebugPackets.Packets.DEBUG_BRAIN)
end

function DebugPackets.createBrainDump(agent: Agent.Agent): BrainDebugPayload.BrainDump
	local brain = agent:getBrain()
	local brainDump: BrainDebugPayload.BrainDump = {}

	brainDump.memories = DebugPackets.getMemoryDescriptions(agent)
	brainDump.activites = {}
	for activity, _ in pairs(brain.activeActivities) do
		table.insert(brainDump.activites, activity.name)
	end
	brainDump.behaviors = {}
	for _, behaviorControl in ipairs(brain:getRunningBehaviors()) do
		table.insert(brainDump.behaviors, behaviorControl.name)
	end
	brainDump.character = agent.character
	brainDump.health = agent.character.Humanoid.Health
	brainDump.maxHealth = agent.character.Humanoid.MaxHealth
	brainDump.name = DebugEntityNameGenerator.getEntityName(agent)
	brainDump.uuid = agent:getUuid()
	brainDump.detectedStatuses = DebugPackets.getDetectedStatusesDescriptions(agent)
	brainDump.suspicionLevels = {}
	for player, value in pairs(agent:getSuspicionManager().suspicionLevels) do
		if next(value) == nil then
			continue
		end

		table.insert(brainDump.suspicionLevels, `{player.Name}: {DebugPackets.getShortDescription(value)}`)
	end

	return brainDump
end

--

function DebugPackets.getDetectedStatusesDescriptions(agent: Agent.Agent): { string }
	local statusArray: { {status: PlayerStatus.PlayerStatusType, player: Player, priority: number} } = {}

	for status, player in pairs(agent.suspicionManager.detectedStatuses) do
		local statusPriority = PlayerStatus.getStatusPriorityValue(status)
		table.insert(statusArray, {
			status = status,
			player = player,
			priority = statusPriority
		})
	end

	table.sort(statusArray, function(a, b)
		return a.priority > b.priority
	end)

	local descriptions = {}
	for _, item in ipairs(statusArray) do
		table.insert(descriptions, tostring(item.status))
	end
	
	return descriptions
end

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
		-- we represent enums like this.
		-- an example is MemoryStatus. But since we're using memories, see PatrolState.
		if tableOnlyHasOneEntry(t) and t["name"] and type(t.name) == "string" then
			return t.name:upper()
		end

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