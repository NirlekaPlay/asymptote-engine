--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local PlayerActiveSessionMetadata = require(ServerScriptService.server.teleportation.metadata.PlayerActiveSessionMetadata)

local TELE_SERVER_METDATA_TTL = 300
local ACTIVE_SESSION_METDATA_TTL = 43200
local TELE_SERVER_METDATA_NAME = "ReservedServerMetadata"
local ACTIVE_SESSIONS_MEMORY_NAME = "ActiveSessions"

local teleportDataMemoryStore = MemoryStoreService:GetHashMap(TELE_SERVER_METDATA_NAME)
local activeSessionsMemoryStore = MemoryStoreService:GetHashMap(ACTIVE_SESSIONS_MEMORY_NAME)

--[=[
	@class Teleportation
]=]
local Teleportation = {}

function Teleportation.init(): any
	if Teleportation.isReservedServer() then
		return Teleportation.initReservedServer()
	end

	return nil
end

function Teleportation.initReservedServer(): any
	local accessCode = game.PrivateServerId
	if accessCode == "" then
		warn(`'PrivateServerId' is an empty string`)
		return
	end

	local success, data = pcall(function()
		return teleportDataMemoryStore:GetAsync(accessCode)
	end)

	if success and data then
		pcall(function()
			teleportDataMemoryStore:RemoveAsync(accessCode)
		end)
		
		print("Metadata consumed and cleared for code:", accessCode)
		return data
	else
		warn(`There was an error trying to fetch teleport data from memory store '{TELE_SERVER_METDATA_NAME}' for access code {accessCode}: {data}`)
	end

	return nil
end

--

function Teleportation.teleportPlayerToFriendIfFollowing(player: Player): ()
	local followId = player.FollowUserId

	if followId and followId > 0 then
		local success, rawData = pcall(function()
			return activeSessionsMemoryStore:GetAsync(tostring(followId))
		end)

		local data = rawData :: PlayerActiveSessionMetadata.PlayerActiveSessionMetadata

		if success and data then
			if data.jobId == game.JobId then
				return
			end

			if data.allowJoining then
				TeleportService:TeleportToPlaceInstance(data.placeId, data.jobId, player)
			end
		else
			warn(`There was an error trying to fetch session data from memory store '{ACTIVE_SESSIONS_MEMORY_NAME}' for player {player.Name}: {rawData}`)
		end
	end
end

function Teleportation.createReservedSession(owner: Player, placeId: number, data: any): string
	local success, accessCode, privateServerId = (pcall :: any)(function()
		return TeleportService:ReserveServerAsync(placeId)
	end)

	if success and accessCode and privateServerId then
		teleportDataMemoryStore:SetAsync(privateServerId, data, TELE_SERVER_METDATA_TTL)
		return accessCode
	end
	
	error("Failed to reserve server: " .. tostring(accessCode))
end

--

function Teleportation.isReservedServer(): boolean
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		return true
	else
		return false
	end
end

--

function Teleportation.onPlayerAdded(player: Player): ()
	local activeSessionMetdata: PlayerActiveSessionMetadata.PlayerActiveSessionMetadata = {
		placeId = game.PlaceId,
		jobId = game.JobId,
		allowJoining = true
	}

	activeSessionsMemoryStore:SetAsync(tostring(player.UserId), activeSessionMetdata, ACTIVE_SESSION_METDATA_TTL)

	Teleportation.teleportPlayerToFriendIfFollowing(player)
end

function Teleportation.onPlayerRemoving(player: Player): ()
	activeSessionsMemoryStore:RemoveAsync(tostring(player.UserId))
end

function Teleportation.onServerClosing(): ()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			activeSessionsMemoryStore:RemoveAsync(tostring(player.UserId))
		end)
	end
end

return Teleportation