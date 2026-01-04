--!nonstrict

local RunService = game:GetService('RunService')
local MAX_RETRIES = 8

--[=[
	@class CoreCall

	Allows to call Roblox services early, as they may be unregistered.
]=]
local CoreCall = {}

function CoreCall.call(service: string, method: string, ...)
	local result = {}
	service = game:GetService(service)
	for retries = 1, MAX_RETRIES do
		result = {pcall(service[method], service, ...)}
		if result[1] then
			break
		end
		RunService.Stepped:Wait()
	end
	return unpack(result)
end

return CoreCall