--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ASSETS_FOLDER_NAME = "Assets"
local PROPS_FOLDER_NAME = "Props"
local PROP_BASE_PART_NAME = "Base"
local PROP_COLOR_ATTRIBUTE_PREFIX = "Color"
local PROP_MATERIAL_ATTRIBUTE_PREFIX = "Material"
local assetsFolder = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER_NAME)
local sharedPropsFolder -- im breaking my own code.

--[=[
	@class Clutter

	# The Clutter System
	Based on Infiltration Engine's prop system.

	```
	PropName (Model)
	├── Base (Part) -- REQUIRED: Reference point for positioning and spawning
	├── Part0 (BasePart) -- Optional: Can be recolored via Color0/Material0 attributes
	├── Part1 (BasePart) -- Optional: Can be recolored via Color1/Material1 attributes
	├── Part2 (BasePart) -- Optional: Can be recolored via Color2/Material2 attributes
	├── Part3, Part4, etc. -- Optional: Pattern continues (Color3/Material3, etc.)
	└── Any other parts/objects -- Optional: Will be positioned but not recolored
	```
]=]
local Clutter = {}

function Clutter.initialize(): boolean
	if not assetsFolder then
		warn(`{ASSETS_FOLDER_NAME} not found in ReplicatedStorage.`)
		return false
	end

	if not assetsFolder:IsA("Model") or assetsFolder:IsA("Folder") then
		warn(`{ASSETS_FOLDER_NAME} should be a Model or a Folder. Got '{assetsFolder.ClassName}'`)
		return false
	end

	local propsFolder = assetsFolder:FindFirstChild(PROPS_FOLDER_NAME)
	if propsFolder then
		if propsFolder:IsA("Model") or propsFolder:IsA("Folder") then
			Clutter.checkInvalidProps(propsFolder)
			sharedPropsFolder = propsFolder
		else
			warn(`{PROPS_FOLDER_NAME} should be a Model or a Folder. Got '{propsFolder.ClassName}'`)
			return false
		end
	end

	return true
end

function Clutter.replacePlaceholdersWithProps(levelPropsFolder: Model | Folder, colorsMap: { [string]: Color3 }?, callback: ((placeholder: BasePart, passed: boolean, prop: Model & { Base: BasePart }) -> boolean)?): ()
	for _, child in ipairs(levelPropsFolder:GetChildren()) do
		if not child:IsA("BasePart") then
			continue
		end

		local propName = child.Name
		local prop = Clutter.getPropByName(propName)
		if not prop then
			if callback then
				local success = callback(child, false)
				if success then
					continue
				end
			end

			warn(`Unknown prop '{propName}' at {child:GetFullName()}`)
			
			continue
		end

		local propClone = prop:Clone() :: Model -- why tf is it `any`
		Clutter.positionProp(propClone, child)
		Clutter.recolorProp(propClone, child, colorsMap)

		propClone.Parent = levelPropsFolder

		if callback then
			callback(child, true, propClone)
		end
		child:Destroy()
	end
end

function Clutter.positionProp(propModel: Model, placeholder: BasePart): ()
	local base = propModel:FindFirstChild("Base", true)
	if base and base:IsA("BasePart") then
		local diff = placeholder.CFrame * base.CFrame:Inverse()
		for _, p in pairs(propModel:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CFrame = diff * p.CFrame
			end
		end
	end
end

function Clutter.recolorProp(propModel: Model, placeholder: BasePart, colorsMap: { [string]: Color3 }?)
	local index = 0
	local colors: { [string]: { color: (Color3 | BrickColor)?, material: Enum.Material? } } = {}
	
	while true do
		local colour = placeholder:GetAttribute(PROP_COLOR_ATTRIBUTE_PREFIX .. index)
		local material = placeholder:GetAttribute(PROP_MATERIAL_ATTRIBUTE_PREFIX .. index)

		if not colour and not material then
			break 
		end

		if colour or material then
			colors["Part" .. index] = {}
			
			if colour then
				if typeof(colour) == "string" then
					if colour ~= "" then
						colour = nil -- kind ignore that shit
					end
					if colorsMap then
						local mappedColor = colorsMap[colour :: any]
						if mappedColor then
							colour = mappedColor
						else
							warn(`Color key '{colour}' not found in colorsMap for {placeholder:GetFullName()}`)
							colour = nil
						end
					else
						error(`Failed to set {PROP_COLOR_ATTRIBUTE_PREFIX}{index} color for {placeholder:GetFullName()}: String color key '{colour}' provided but no colorsMap available`)
					end
				end
				
				if colour then
					local isValidColor = Clutter.isValidColor(colour)
					if not isValidColor then
						error(`Failed to set {PROP_COLOR_ATTRIBUTE_PREFIX}{index} color for {placeholder:GetFullName()}: Given color attribute value must be of type Color3 or BrickColor. Got '{typeof(colour)}'`)
					end
					colors["Part" .. index].color = colour :: any
				end
			end
			
			if material then
				local isValidMaterial, errMsg = Clutter.isValidMaterial(material)
				if not isValidMaterial and errMsg then
					error(`Failed to set {PROP_MATERIAL_ATTRIBUTE_PREFIX}{index} material for {placeholder:GetFullName()}: {errMsg}`)
				end
				colors["Part" .. index].material = material :: any
			end
		end
		index += 1
	end

	for _, part in pairs(propModel:GetDescendants()) do
		if part:IsA("BasePart") and colors[part.Name] then
			local attributes = colors[part.Name]
			if attributes.color then
				if typeof(attributes.color) == "Color3" then
					part.Color = attributes.color
				else
					part.BrickColor = attributes.color
				end
			end

			if attributes.material then
				part.Material = attributes.material
			end
		end
	end
end

function Clutter.isValidMaterial(material: any): (boolean, string?)
	if type(material) ~= "string" then
		return false, `Materials should only be described with strings. Got '{typeof(material)}'`
	end

	local forceFieldEnum = Enum.Material:FromName(material)
	if not forceFieldEnum then
		return false, `'{material}' is not a valid member of Enum.Materials enum.`
	end

	return true, nil
end

function Clutter.isValidColor(color: any): boolean
	if not (typeof(color) == "Color3" or 
		typeof(color) == "BrickColor") then
			return false
	end

	return true
end

function Clutter.getPropByName(propName: string): Model?
	if not sharedPropsFolder then
		error("Attempt to get prop when props folder is nil.")
	end

	local model = (sharedPropsFolder :: Model | Folder):FindFirstChild(propName)
	if not model or not model:IsA("Model") then
		return nil
	end

	return model
end

--

function Clutter.checkInvalidProps(propsFolder: Model | Folder): ()
	for _, propModel in ipairs(propsFolder:GetChildren()) do
		if not propModel:IsA("Model") then
			continue
		end

		local isValid, errMsg = Clutter.isPropValid(propModel)
		if not isValid and errMsg then
			warn(`{propModel:GetFullName()} is invalid: {errMsg}`)
			continue
		end
	end
end

function Clutter.isPropValid(propModel: Model): (boolean, string?)
	local basePart = propModel:FindFirstChild(PROP_BASE_PART_NAME, true)
	if not basePart then
		return false, `{PROP_BASE_PART_NAME} not found.`
	elseif not basePart:IsA("BasePart") then
		return false, `{PROP_BASE_PART_NAME} should be a BasePart. Got '{basePart.ClassName}'`
	end

	return true, nil
end

--

return Clutter