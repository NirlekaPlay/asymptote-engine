--!strict

--[=[
	@class FriendlyByteBuf
]=]
local FriendlyByteBuf = {}
FriendlyByteBuf.__index = FriendlyByteBuf

export type FriendlyByteBuf = typeof(setmetatable({} :: {
	_bytes: {number},
	_pos: number
}, FriendlyByteBuf))

function FriendlyByteBuf.new(src: buffer?): FriendlyByteBuf
	local self = setmetatable({
		_bytes = {},
		_pos = 1
	}, FriendlyByteBuf)

	if src then
		local len = buffer.len(src)
		for i = 0, len - 1 do
			self._bytes[i + 1] = buffer.readu8(src, i)
		end
	end

	return self
end

function FriendlyByteBuf.pushByte(self: FriendlyByteBuf, b: number): ()
	self._bytes[#self._bytes + 1] = b -- TODO: `#` is slow as fuck
end

function FriendlyByteBuf.writeByte(self: FriendlyByteBuf, value: number)
	self:pushByte(value % 256)
end

function FriendlyByteBuf.writeVarInt(self: FriendlyByteBuf, value: number)
	-- LEB128 unsigned 32-bit
	value = value % 0x100000000  -- treat as uint32
	repeat
		local b = value % 128
		value = math.floor(value / 128)
		if value ~= 0 then b = b + 128 end
		self:pushByte(b)
	until value == 0
end

function FriendlyByteBuf.writeVarIntArray(self: FriendlyByteBuf, arr: {number})
	self:writeVarInt(#arr)
	for _, v in ipairs(arr) do
		self:writeVarInt(v)
	end
end

function FriendlyByteBuf.writeUtf(self: FriendlyByteBuf, s: string)
	-- length-prefixed UTF-8
	self:writeVarInt(#s)
	for i = 1, #s do -- TODO: # is slow as fuck
		self:pushByte(string.byte(s, i))
	end
end

function FriendlyByteBuf.writeResourceLocation(self: FriendlyByteBuf, loc: string)
	self:writeUtf(loc)
end

--

function FriendlyByteBuf.pullByte(self: FriendlyByteBuf): number
	local b = self._bytes[self._pos]
	if b == nil then
		error("FriendlyByteBuf: read past end")
	end
	self._pos += 1
	return b
end

function FriendlyByteBuf.readByte(self: FriendlyByteBuf): number
	return self:pullByte()
end

function FriendlyByteBuf.readVarInt(self: FriendlyByteBuf): number
	local result = 0
	local shift  = 0
	repeat
		local b = self:pullByte()
		result = result + (b % 128) * (128 ^ shift)
		shift += 1
		if shift > 5 then error("VarInt too long") end
		if b < 128 then break end
	until false
	return math.floor(result)
end

function FriendlyByteBuf.readVarIntArray(self: FriendlyByteBuf): {number}
	local len = self:readVarInt()
	local arr: {number} = {}
	for i = 1, len do
		arr[i] = self:readVarInt()
	end
	return arr
end

function FriendlyByteBuf.readUtf(self: FriendlyByteBuf): string
	local len = self:readVarInt()
	local chars = {}
	for i = 1, len do
		chars[i] = string.char(self:pullByte())
	end
	return table.concat(chars)
end

function FriendlyByteBuf.readResourceLocation(self: FriendlyByteBuf): string
	return self:readUtf()
end

function FriendlyByteBuf.toBuffer(self: FriendlyByteBuf): buffer
	local buf = buffer.create(#self._bytes)
	for i, b in self._bytes do
		buffer.writeu8(buf, i - 1, b)
	end
	return buf
end

--

function FriendlyByteBuf.dump(self: FriendlyByteBuf)
	local width = 16
	local output = {
		string.format("Dumping %d bytes:", #self._bytes),
		"Offset    00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F  ASCII Text",
		"--------  -----------------------  -----------------------  ----------------"
	}

	for i = 1, #self._bytes, width do
		local hexParts = {}
		local charParts = {}
		
		for j = 0, width - 1 do
			local b = self._bytes[i + j]
			
			if b then
				table.insert(hexParts, string.format("%02X", b))
				table.insert(charParts, (b >= 32 and b <= 126) and string.char(b) or ".")
			else
				table.insert(hexParts, "  ")
				table.insert(charParts, " ")
			end

			if j == 7 then table.insert(hexParts, "") end
		end

		local line = string.format("%08X  %s  |%s|", i - 1, table.concat(hexParts, " "), table.concat(charParts, ""))
		table.insert(output, line)
	end

	print(table.concat(output, "\n"))
end

return FriendlyByteBuf