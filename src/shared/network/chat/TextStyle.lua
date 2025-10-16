--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextColor = require(ReplicatedStorage.shared.network.chat.TextColor)

--[=[
	@class TextStyle

	An immutable class that represents a text style.
]=]
local TextStyle = {}
TextStyle.__index = TextStyle

local EMPTY: TextStyle? = nil

export type TextStyle = typeof(setmetatable({} :: {
	color: TextColor.TextColor?,
	shadowColor: TextColor.TextColor?,
	bold: boolean?,
	italic: boolean?,
	obfuscated: boolean?
}, TextStyle))

function TextStyle.new(
	color: TextColor.TextColor?,
	shadowColor: TextColor.TextColor?,
	bold: boolean?,
	italic: boolean?,
	obfuscated: boolean?
): TextStyle
	return setmetatable({
		color = color,
		shadowColor = shadowColor,
		bold = bold,
		italic = italic,
		obfuscated = obfuscated
	}, TextStyle) :: TextStyle
end

function TextStyle.empty(): TextStyle
	if not EMPTY then
		EMPTY = TextStyle.new()
		return EMPTY :: any
	else
		return EMPTY
	end
end

function TextStyle.isEmpty(textStyle: TextStyle): boolean
	if EMPTY ~= nil and textStyle == EMPTY then
		return true
	else
		-- Should probably use a table containing the styles
		-- so we can just do `next(t) == nil` but eh.
		return textStyle.bold == nil
			and textStyle.color == nil
			and textStyle.italic == nil
			and textStyle.obfuscated == nil
	end
end

function TextStyle.checkEmptyAfterChange<T>(newStyle: TextStyle, oldValue: T, newValue: T): TextStyle
	return if (
		(oldValue :: any) ~= nil and
		(newValue :: any) == nil and
		TextStyle.isEmpty(newStyle) ) then TextStyle.empty() else newStyle 
end

function TextStyle.withColor(self: TextStyle, textColor: TextColor.TextColor): TextStyle
	if (self.color and self.color.colorValue == textColor.colorValue) then
		return self
	else
		return TextStyle.checkEmptyAfterChange(
			TextStyle.new(
				textColor,
				self.shadowColor,
				self.bold,
				self.italic,
				self.obfuscated
			),
			self.color,
			textColor
		)
	end
end

function TextStyle.withShadowColor(self: TextStyle, shadowColor: TextColor.TextColor): TextStyle
	if (self.shadowColor and self.shadowColor.colorValue == shadowColor.colorValue) then
		return self
	else
		return TextStyle.checkEmptyAfterChange(
			TextStyle.new(
				self.color,
				shadowColor,
				self.bold,
				self.italic,
				self.obfuscated
			),
			self.shadowColor,
			shadowColor
		)
	end
end

function TextStyle.withBold(self: TextStyle, bold: boolean?): TextStyle
	if self.bold == bold then
		return self
	else
		return TextStyle.checkEmptyAfterChange(
			TextStyle.new(
				self.color,
				self.shadowColor,
				bold,
				self.italic,
				self.obfuscated
			),
			self.bold,
			bold
		)
	end
end

function TextStyle.withItalic(self: TextStyle, italic: boolean?): TextStyle
	if self.italic == italic then
		return self
	else
		return TextStyle.checkEmptyAfterChange(
			TextStyle.new(
				self.color,
				self.shadowColor,
				self.bold,
				italic,
				self.obfuscated
			),
			self.italic,
			italic
		)
	end
end

function TextStyle.withObfuscated(self: TextStyle, obfuscated: boolean?): TextStyle
	if self.obfuscated == obfuscated then
		return self
	else
		return TextStyle.checkEmptyAfterChange(
			TextStyle.new(
				self.color,
				self.shadowColor,
				self.bold,
				self.italic,
				obfuscated
			),
			self.obfuscated,
			obfuscated
		)
	end
end

function TextStyle.applyTo(self: TextStyle, otherStyle: TextStyle): TextStyle
	if self:isEmpty() then
		return otherStyle
	else
		if otherStyle:isEmpty() then
			return self
		else
			return TextStyle.new(
				self.color and self.color or otherStyle.color,
				self.shadowColor and self.shadowColor or otherStyle.shadowColor,
				self.bold and self.bold or otherStyle.bold,
				self.italic and self.italic or otherStyle.italic,
				self.obfuscated and self.obfuscated or otherStyle.obfuscated
			)
		end
	end
end

--

function TextStyle.serialize(self: TextStyle): { [string]: any }
	local data: { [string]: any } = {}

	if self.color then
		data.color = self.color:serialize()
	end

	if self.shadowColor then
		data.shadowColor = self.shadowColor:serialize()
	end

	if self.bold ~= nil then
		data.bold = self.bold
	end

	if self.italic ~= nil then
		data.italic = self.italic
	end

	if self.obfuscated ~= nil then
		data.obfuscated = self.obfuscated
	end

	return data
end

function TextStyle.deserialize(data: { [string]: any }): TextStyle
	local color = if data.color then TextColor.deserialize(data.color :: any) else nil
	local shadowColor = if data.shadowColor then TextColor.deserialize(data.shadowColor :: any) else nil

	return TextStyle.new(
		color,
		shadowColor,
		data.bold,
		data.italic,
		data.obfuscated
	)
end


return TextStyle