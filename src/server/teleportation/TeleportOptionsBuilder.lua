--!strict

--[=[
	@class TeleportOptionsBuilder
]=]
local TeleportOptionsBuilder = {}
TeleportOptionsBuilder.__index = TeleportOptionsBuilder

export type TeleportOptionsBuilder = typeof(setmetatable({} :: {
	_reservedServerAccessCode: string?,
	_serverInstanceId: string?,
	_shouldReserveServer: boolean?,
	_teleportData: TeleportData?
}, TeleportOptionsBuilder))

type TeleportData = boolean | buffer | number | string | { [string]: any }

function TeleportOptionsBuilder.new(): TeleportOptionsBuilder
	return setmetatable({}, TeleportOptionsBuilder) :: TeleportOptionsBuilder
end

function TeleportOptionsBuilder.reservedServerAccessCode(self: TeleportOptionsBuilder, code: string): TeleportOptionsBuilder
	self._reservedServerAccessCode = code
	return self
end

function TeleportOptionsBuilder.shouldReserveServer(self: TeleportOptionsBuilder, should: boolean): TeleportOptionsBuilder
	self._shouldReserveServer = should
	return self
end

function TeleportOptionsBuilder.serverInstanceId(self: TeleportOptionsBuilder, id: string): TeleportOptionsBuilder
	self._serverInstanceId = id
	return self
end

function TeleportOptionsBuilder.withTeleportData(self: TeleportOptionsBuilder, data: TeleportData): TeleportOptionsBuilder
	self._teleportData = data
	return self
end

function TeleportOptionsBuilder.build(self: TeleportOptionsBuilder): TeleportOptions
	local newTelOpt = Instance.new("TeleportOptions")

	if self._reservedServerAccessCode then
		newTelOpt.ReservedServerAccessCode = self._reservedServerAccessCode
	end

	if self._serverInstanceId then
		newTelOpt.ServerInstanceId = self._serverInstanceId
	end

	if self._shouldReserveServer ~= nil then
		newTelOpt.ShouldReserveServer = self._shouldReserveServer
	end

	if self._teleportData then
		newTelOpt:SetTeleportData(self._teleportData :: any)
	end

	return newTelOpt
end

return TeleportOptionsBuilder