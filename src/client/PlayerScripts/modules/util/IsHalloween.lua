--!strict

--[=[
	Returns true if the current time is considered halloween,
	which is the month of October.
]=]
return function(): boolean
	local currentMonth = tonumber(os.date("%m")) -- Returns month as number (1-12)
	return currentMonth == 10
end
