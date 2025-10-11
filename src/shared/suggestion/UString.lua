--!strict

--[=[
	@class UString

	A modern version of [Dasar](https://github.com/Nirleka-Studio/dasar)'s
	[ustring](https://github.com/Nirleka-Studio/dasar/blob/master/src/library/string/ustring.lua)
	library.

	Provides Unicode aware utility functions for strings.
]=]
local UString = {}

--[=[
	Splits a string into its individual Unicode characters and returns them as a table.

	This function correctly handles multi-byte Unicode characters, ensuring that 
	characters like emojis or accented letters are not broken into invalid byte sequences.

	```lua
	local str = "月が綺麗ですね。"
	local exploded = UString.explodeString(str)
	```

	```
	{
		[1] = "月",
		[2] = "が",
		[3] = "綺",
		[4] = "麗",
		[5] = "で",
		[6] = "す",
		[7] = "ね",
		[8] = "。"
	}
	```
]=]
function UString.explodeString(str: string): { string }
	local length = utf8.len(str) :: number
	local chars = table.create(length, true) :: { string }

	-- string.sub() and others operates on bytes. So multibyte characters like `月`
	-- will result in an unknown character. `�`

	local i = 0
	for p, c in utf8.codes(str) do
		i += 1
		chars[i] = utf8.char(c)
	end

	return chars
end

--[=[
	Computes the Damerau-Levenshtein distance between two strings.

	The Damerau-Levenshtein distance measures the minimum number of operations 
	required to transform one string into another. The allowed operations are:
	 * Insertion of a character
	 * Deletion of a character
	 * Substitution of one character for another
	 * Transposition (swap) of two adjacent characters

	This implementation properly handles Unicode strings by first splitting 
	them into individual characters, ensuring multi-byte characters (e.g., emojis, 
	accented letters) are treated as single units.

	```lua
	local distance = UString.damerauLevenshteinDistance("example", "samples")
	-- distance = 3
	```
]=]
function UString.damerauLevenshteinDistance(str1: string, str2: string): number
	local str1Length = utf8.len(str1) :: number
	local str2Length = utf8.len(str2) :: number
	local str1Chars = UString.explodeString(str1)
	local str2Chars = UString.explodeString(str2)
	local d: {{number}} = {}

	for i = 0, str1Length do
		d[i] = {}
		for j = 0, str2Length do
			d[i][j] = 0
		end
	end

	local lCost: number

	for i = 1, str1Length do
		d[i][0] = i
	end

	for j = 1, str2Length do
		d[0][j] = j
	end

	for i = 1, str1Length do
		for j = 1, str2Length do
			if str1Chars[i - 1] == str2Chars[j - 1] then
				lCost = 0
			else
				lCost = 1
			end

			d[i][j] = math.min(
				d[i - 1][j] + 1,
				math.min(
					d[i][j-1] + 1,
					d[i - 1][j - 1] + lCost
				)
			)

			if i > 1 and
				j > 1 and
				str1Chars[i - 1] == str2Chars[j - 2] and
				str1Chars[i - 2] == str2Chars[j - 1] then

				
				d[i][j] = math.min(
					d[i][j],
					d[i - 2][j - 2] + lCost
				)
			end
		end
	end

	return d[str1Length][str2Length]
end

function UString.isWhitespace(char: string): boolean
	if #char == 0 then
		return false
	end
	
	local codepoint = utf8.codepoint(char)
	
	-- Control characters (0x09-0x0D, 0x1C-0x1F)
	if (codepoint >= 0x0009 and codepoint <= 0x000D) or 
	   (codepoint >= 0x001C and codepoint <= 0x001F) then
		return true
	end
	
	-- Space separators and specific whitespace characters
	return codepoint == 0x0020  -- Space
		or codepoint == 0x00A0  -- Non-breaking space
		or codepoint == 0x1680  -- Ogham space mark
		or (codepoint >= 0x2000 and codepoint <= 0x200A)  -- Various spaces (en, em, thin, etc.)
		or codepoint == 0x2028  -- Line separator
		or codepoint == 0x2029  -- Paragraph separator
		or codepoint == 0x202F  -- Narrow no-break space
		or codepoint == 0x205F  -- Medium mathematical space
		or codepoint == 0x3000  -- Ideographic space
end

return UString