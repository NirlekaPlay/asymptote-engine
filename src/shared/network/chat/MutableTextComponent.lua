--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local RICH_TEXT_FONT_COLOR = '<font color="%s">%s</font>'
local RICH_TEXT_BOLD = '<b>%s</b>'
local RICH_TEXT_ITALIC = '<i>%s</i>'
local OBFUSCATED_CHAR = "█"
local ESCAPE_CHARS = {
	["<"]  = "&lt;",
	[">"]  = "&gt;",
	['"']  = "&quot;",
	["'"]  = "&apos;"
}

--[=[
	@class MutableTextComponent

	A builder class that can be mutated to consistently build
	texts with type-safe methods and build the actual
	rich text markup string.
]=]
local MutableTextComponent = {}
MutableTextComponent.__index = MutableTextComponent

export type MutableTextComponent = {
	contents: string, -- make it a string for now...
	style: TextStyle.TextStyle,
	siblings: { MutableTextComponent },
	--
	withStyle: (self: MutableTextComponent, style: TextStyle.TextStyle) -> MutableTextComponent,
	appendString: (self: MutableTextComponent, str: string) -> MutableTextComponent,
	appendComponent: (self: MutableTextComponent, component: MutableTextComponent) -> MutableTextComponent,
	serialize: (self: MutableTextComponent) -> SerializedComponentResult,
	buildRichTextMarkupString: (self: MutableTextComponent) -> string
}

export type SerializedComponentResult = {
	contents: string,
	style: { [string]: any },
	siblings: { SerializedComponentResult }
}

function MutableTextComponent.new(
	contents: string,
	style: TextStyle.TextStyle,
	siblings: { MutableTextComponent }
): MutableTextComponent
	return setmetatable({
		contents = contents,
		style = style,
		siblings = siblings
	}, MutableTextComponent) :: MutableTextComponent
end

function MutableTextComponent.literal(str: string): MutableTextComponent
	return MutableTextComponent.new(
		str,
		TextStyle.empty(),
		{}
	)
end

function MutableTextComponent.withStyle(self: MutableTextComponent, style: TextStyle.TextStyle): MutableTextComponent
	self.style = style
	return self
end

function MutableTextComponent.appendString(self: MutableTextComponent, str: string): MutableTextComponent
	table.insert(self.siblings, MutableTextComponent.literal(str))
	return self
end

function MutableTextComponent.appendComponent(self: MutableTextComponent, component: MutableTextComponent): MutableTextComponent
	table.insert(self.siblings, component)
	return self
end

--

function MutableTextComponent.serialize(self: MutableTextComponent): SerializedComponentResult
	-- TODO: Should probably use the stackSize instead of the table.insert and table.remove.
	-- but eh.
	local stack: { { pos: MutableTextComponent, serialized: SerializedComponentResult } } = {}
	local stackSize = 0

	local result: SerializedComponentResult = {
		contents = self.contents,
		style = self.style:serialize(),
		siblings = {}
	}
	table.insert(stack, { pos = self, serialized = result } )
	stackSize += 1

	while stackSize > 0 do
		local stackPos = stack[stackSize]
		local current = stackPos.pos
		local serialized = stackPos.serialized

		table.remove(stack, stackSize)
		stackSize -= 1

		for _, sibling in ipairs(current.siblings) do
			local serializedSibling: SerializedComponentResult = {
				contents = sibling.contents,
				style = sibling.style:serialize(),
				siblings = {}
			}

			table.insert(serialized.siblings, serializedSibling)
			table.insert(stack, { pos = sibling, serialized = serializedSibling } )
			stackSize += 1
		end
	end

	return result
end

function MutableTextComponent.deserialize(data: SerializedComponentResult): MutableTextComponent
	local root = MutableTextComponent.new(data.contents, TextStyle.deserialize(data.style), {})
	
	local stack: { { component: MutableTextComponent, data: SerializedComponentResult } } = {}
	local stackSize = 0

	table.insert(stack, { component = root, data = data })
	stackSize += 1
	
	while stackSize > 0 do
		local current = stack[stackSize]
		table.remove(stack, stackSize)
		stackSize -= 1

		for _, siblingData in ipairs(current.data.siblings) do
			local sibling = MutableTextComponent.new(
				siblingData.contents,
				TextStyle.deserialize(siblingData.style),
				{}
			)
			current.component:appendComponent(sibling)

			table.insert(stack, { component = sibling, data = siblingData })
			stackSize += 1
		end
	end
	
	return root
end

function MutableTextComponent.buildRichTextMarkupString(self: MutableTextComponent): string
	local result = ""

	local stack: { { component: MutableTextComponent, inheritedStyle: TextStyle.TextStyle } } = {}
	local stackSize = 0
	
	table.insert(stack, { component = self, inheritedStyle = TextStyle.empty() })
	stackSize += 1
	
	while stackSize > 0 do
		local current = stack[stackSize]
		table.remove(stack, stackSize)
		stackSize -= 1
		
		local component = current.component
		local combinedStyle = component.style:applyTo(current.inheritedStyle)

		local text = component.contents
		if text and text ~= "" then
			result ..= MutableTextComponent.applyStyle(
				MutableTextComponent.escapeRichTextChar(text), combinedStyle
			)
		end
		
		-- Push siblings in REVERSE order so they process left-to-right
		for i = #component.siblings, 1, -1 do
			table.insert(stack, {
				component = component.siblings[i],
				inheritedStyle = combinedStyle
			})
			stackSize += 1
		end
	end
	
	return result
end

--

function MutableTextComponent.escapeRichTextChar(str: string): string
	local escaped = str:gsub("[<>\'\"']", ESCAPE_CHARS)
	escaped = escaped:gsub("%s*\n%s*", "<br/>")

	return escaped
end

function MutableTextComponent.applyStyle(text: string, style: TextStyle.TextStyle): string
	local output = text

	if style.obfuscated then
		output = string.rep(OBFUSCATED_CHAR, utf8.len(output) :: number)
	end
	
	if style.bold then
		output = string.format(RICH_TEXT_BOLD :: any, output)
	end
	
	if style.italic then
		output = string.format(RICH_TEXT_ITALIC :: any, output)
	end
	
	if style.color then
		local hex = style.color:toHex()
		output = string.format(RICH_TEXT_FONT_COLOR :: any, hex, output)
	end
	
	return output
end

return MutableTextComponent