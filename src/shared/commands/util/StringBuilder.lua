--!strict

local type = type
local table_concat = table.concat
local table_insert = table.insert
local tostring = tostring

--[=[
	@class StringBuilder
]=]
local StringBuilder = {}
StringBuilder.__index = StringBuilder

export type StringBuilder = typeof(setmetatable({} :: {
	dict: {string}
}, StringBuilder))

function StringBuilder.new(): StringBuilder
	return setmetatable({
		dict = {}
	}, StringBuilder)
end

function StringBuilder.append<T>(self: StringBuilder, value: T): StringBuilder
	if type(value) == "string" then
		table_insert(self.dict, value)
	else
		table_insert(self.dict, tostring(value))
	end

	return self
end

function StringBuilder.toString(self: StringBuilder): string
	return table_concat(self.dict)
end

return StringBuilder