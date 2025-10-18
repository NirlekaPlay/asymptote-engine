--!strict

local Lighting = game:GetService("Lighting")

local LightingSetter = {}

local PROPERTIES_STRING = "$properties"

local instanceClassNamesCache: { [string]: true } = {}

function LightingSetter.readConfig(config: { [string]: any }): ()
	-- remove instances not in config
	for _, child in Lighting:GetChildren() do
		local isInConfig = false
		for instName, _ in pairs(config) do
			if instName ~= "Lighting" and child.ClassName == instName then
				isInConfig = true
				break
			end
		end
		if not isInConfig then
			child:Destroy()
		end
	end
	
	-- apply configs
	for instName, v in pairs(config) do
		local instance: Instance
		if instName == "Lighting" then
			instance = Lighting
		else
			instance = LightingSetter.getInstanceByName(instName)
		end
		
		if type(v) ~= "table" then
			error(`{instName} must have a table`)
		end
		
		local properties = (v :: { [string]: any })[PROPERTIES_STRING] :: { [string]: {number} | string | number | boolean }
		if properties == nil then
			error(`The table under {instName} must have a '{PROPERTIES_STRING}' field.`)
		end
		
		LightingSetter.applyProperties(instance, properties)
		
		if not instance:IsA("Lighting") then
			local existing = Lighting:FindFirstChildOfClass(instance.ClassName)
			if existing then
				existing:Destroy()
			end
			instance.Parent = Lighting
		end
	end
end

function LightingSetter.getInstanceByName(instName: string): Instance
	if instanceClassNamesCache[instName] then
		-- Its better to just start off fresh
		--local existing = Lighting:FindFirstAncestorOfClass(instName)
		--if existing then
		--	return existing
		--else
			return Instance.new(instName)
		--end
	end
	local success, instance = pcall(function()
		return Instance.new(instName)
	end)
	if not success then
		error(`{instName} is not a valid Instance`)
	else
		if instanceClassNamesCache[instName] == nil then
			instanceClassNamesCache[instName] = true
		end
	end
	return instance
end

function LightingSetter.applyProperties(instance: Instance, properties: { [string]: {number} | string | number | boolean })
	local inst = instance :: any
	for property, value in pairs(properties) do
		if typeof(value) == "table" then
			-- Convert tables of 3 numbers to Color3 or Vector3 depending on property type
			if #value == 3 then
				local success = pcall(function()
					-- TODO: Maybe add support for enums, but I don't see any lighting instances using enums
					-- or they can't be set anyway.
					if inst[property] and typeof(inst[property]) == "Color3" then
						inst[property] = Color3.fromRGB(value[1], value[2], value[3])
					elseif inst[property] and typeof(inst[property]) == "Vector3" then
						inst[property] = Vector3.new(value[1], value[2], value[3])
					end
				end)
				if not success then
					warn(`Failed to apply property: '{property}' to instance '{instance.Name}' which is of class '{instance.ClassName}'`)
				end
			end
		else
			local success, err = pcall(function()
				inst[property] = value
				return ""
			end)
			if not success then
				warn(`Property '{property}' failed to set for instance '{instance.Name}' which is of class '{instance.ClassName}'\n{err}`)
			end
		end
	end
end

return LightingSetter