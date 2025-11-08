--!strict

local ScriptEditorService = game:GetService('ScriptEditorService')
local ServerStorage = game:GetService("ServerStorage")

local DEFAULT_PARENT = ServerStorage
local MODULE_TREE_DUMP_PREFIX = "DUMP_TREE_"
local ATTRIBUTES_STRING = "[[ATTRIBUTES]]"

--[=[
	@class StringTreeGenerator
]=]
local StringTreeGenerator = {}

function StringTreeGenerator.generateTreeString(root: Instance, prefix: string?, isLast: boolean?, lines: {string}?): string
	prefix = prefix or ""
	lines = lines or {}
	-- Add the dot at the root level
	if prefix == "" then
		table.insert(lines, ".")
	end
	
	local children = root:GetChildren()
	table.sort(children, function(a: Instance, b: Instance)
		return a.Name < b.Name
	end)
	
	local attributes = root:GetAttributes()
	local attributeKeys = {}
	for key in pairs(attributes) do
		table.insert(attributeKeys, key)
	end
	table.sort(attributeKeys)
	
	local hasAttributes = next(attributes) ~= nil
	local totalItems = #children + (hasAttributes and 1 or 0)
	
	-- Add attributes section FIRST if there are any
	if hasAttributes then
		local isOnlyItem = totalItems == 1
		local branch = isOnlyItem and "└── " or "├── "
		table.insert(lines, prefix .. branch .. ATTRIBUTES_STRING)
		local newPrefix = prefix .. (isOnlyItem and "    " or "│   ")
		for i, key in ipairs(attributeKeys) do
			local isLastAttr = (i == #attributeKeys)
			local attrBranch = isLastAttr and "└── " or "├── "
			local value = attributes[key]
			table.insert(lines, newPrefix .. attrBranch .. key .. ": " .. StringTreeGenerator.getStringOfValue(value))
		end
	end
	
	-- Then process children
	for i, child in ipairs(children) do
		local isLastChild = (i == #children)
		local branch = isLastChild and "└── " or "├── "
		table.insert(lines, prefix .. branch .. child.Name .. ` ({child.ClassName})`)
		local newPrefix = isLastChild and (prefix .. "    ") or (prefix .. "│   ")
		-- Always recurse, even if no children (to check for attributes)
		StringTreeGenerator.generateTreeString(child, newPrefix, isLastChild, lines)
	end
	
	return table.concat(lines, "\n")
end

function StringTreeGenerator.getStringOfValue(value: any): string
	if value == nil then
		return "-"
	elseif type(value) == "string" then
		return string.format("%q", value)
	elseif typeof(value) == "Vector3" then
		return `Vector3\{x={value.X}, y={value.Y}, z={value.Z}\}`
	elseif typeof(value) == "BrickColor" then
		return `BrickColor\{ {(value :: BrickColor).Name} \}`
	elseif typeof(value) == "Color3" then
		return `Color3\{r={value.R}, g={value.G}, b={value.B}\}`
	elseif typeof(value) == "Instance" then
		return (value :: Instance):GetFullName()
	else
		return tostring(value)
	end
end

function StringTreeGenerator.dumpTree(root: Instance, parent: Instance?, module: ModuleScript?): ()
	local str = StringTreeGenerator.generateTreeString(root)
	local targetParent = parent or DEFAULT_PARENT
	local targetModuleScript: ModuleScript
	if module then
		targetModuleScript = module
	else
		local count = 0

		for _, child in targetParent:GetChildren() do
			local isValid = StringTreeGenerator.isValidDumpModule(child)
			if isValid then
				count += 1
			end
		end

		local newDump = Instance.new("ModuleScript")
		newDump.Name = MODULE_TREE_DUMP_PREFIX .. (count + 1)
		newDump.Parent = targetParent
		targetModuleScript = newDump
	end

	ScriptEditorService:UpdateSourceAsync(targetModuleScript, function(oldContent)
		-- Split the string into lines
		local lines = {}
		for line in str:gmatch("([^\n]*)\n?") do
			table.insert(lines, "    " .. line)  -- Add 4 spaces to the start of each line
		end

		-- Join the lines back together with a newline separator
		local indentedStr = table.concat(lines, "\n")

		return "--[=[\n" .. indentedStr .. "\n--]=]"
	end)
end

function StringTreeGenerator.isValidDumpModule(inst: Instance): boolean
	if not inst:IsA("ModuleScript") then
		return false
	end

	local match = string.match(inst.Name, `^{MODULE_TREE_DUMP_PREFIX}(%d+)$`)
	if not match then
		return false
	end

	return true
end

return StringTreeGenerator