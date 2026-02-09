--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")

local TELE_SERVER_METDATA_TTL = 300
local TELE_SERVER_METDATA_NAME = "ReservedServerMetadata"

local teleportDataStore = MemoryStoreService:GetHashMap(TELE_SERVER_METDATA_NAME)

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
		return teleportDataStore:GetAsync(accessCode)
	end)

	if success and data then
		pcall(function()
			teleportDataStore:RemoveAsync(accessCode)
		end)
		
		print("Metadata consumed and cleared for code:", accessCode)
		return data
	else
		warn(`There was an error trying to fetch teleport data from memory store '{TELE_SERVER_METDATA_NAME}' for access code {accessCode}: {data}`)
	end

	return nil
end

--

function Teleportation.createReservedSession(owner: Player, placeId: number, data: any): string
	local success, accessCode, privateServerId = (pcall :: any)(function()
		return TeleportService:ReserveServerAsync(placeId)
	end)

	if success and accessCode and privateServerId then
		teleportDataStore:SetAsync(privateServerId, data, TELE_SERVER_METDATA_TTL)
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

return Teleportation