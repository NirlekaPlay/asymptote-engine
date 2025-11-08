--!strict

local GOLDEN_ANGLE = 137.508
local PLACEHOLDER_TRANSPARENCY = 0.5
local PLACEHOLDER_RECOLOR_IGNORE_DICT = {
	["IntroCam"] = true,
	["SpawnLocation"] = true,
	["MissionEndZone"] = true
}

local function selectColor(number: number)
	local hue = (number * GOLDEN_ANGLE) % 360 / 360  -- convert to 0-1
	local saturation = 0.5  -- 50%
	local value = 0.75      -- 75%
	return Color3.fromHSV(hue, saturation, value)
end

local function recolorPlaceholder(placeholder: BasePart, placeholdersSoFar: number): ()
	placeholder.Transparency = PLACEHOLDER_TRANSPARENCY
	if not PLACEHOLDER_RECOLOR_IGNORE_DICT[placeholder.Name] then
		placeholder.Color = selectColor(placeholdersSoFar)
	end
end

return function(propsFolder: Instance): ()
	local stack = {propsFolder}
	local index = 1
	local processedPlaceholders = 0

	while index > 0 do
		local current = stack[index]
		stack[index] = nil
		index = index - 1

		if current:IsA("BasePart") then
			processedPlaceholders += 1
			recolorPlaceholder(current, processedPlaceholders)
		end

		if current:IsA("Folder") or current:IsA("Model") then
			local children = current:GetChildren()
			for i = #children, 1, -1 do
				index = index + 1
				stack[index] = children[i]
			end
		end
	end
end