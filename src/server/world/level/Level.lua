--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local PropDisguiseGiver = require(ServerScriptService.server.disguise.PropDisguiseGiver)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local Clutter = require(ServerScriptService.server.world.level.clutter.Clutter)
local LightingNames = require(ServerScriptService.server.world.lighting.LightingNames)
local LightingSetter = require(ServerScriptService.server.world.lighting.LightingSetter)

local HIDE_CELLS = true
local DEBUG_MIN_CELLS_TRANSPARENCY = 0.5
local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0

local levelFolder: Folder?
local cellsConfig: { [string]: CellConfig.Config }?
local cellsList: { Model } = {}

--[=[
	@class Level
]=]
local Level = {}

function Level.initializeLevel(): ()
	levelFolder = workspace:FindFirstChild("Level") :: Folder?
	if not levelFolder or not levelFolder:IsA("Folder") then
		warn("Unable to initialize Level: Level not found in Workspace or is not a Folder.")
		return
	end

	local missionSetupModule = levelFolder:FindFirstChild("MissionSetup") :: ModuleScript?
	if not missionSetupModule or not missionSetupModule:IsA("ModuleScript") then
		error("Unable to initialize Mission: MissionSetup module not found in Level folder or is not a ModuleScript.")
	else
		cellsConfig = (require :: any)(missionSetupModule).Cells
	end

	-- TODO: Should probably parse it first THEN create a mission object with getter methods
	-- or something.
	if (require :: any)(missionSetupModule).CustomDisguises == nil then
		error("CustomDisguises is nil in MissionSetup. Must atleast be an empty table.")
	end

	if (require :: any)(missionSetupModule).LightingSettings ~= nil then
		local lightingPresetName = (require :: any)(missionSetupModule).LightingSettings
		local lightingPreset = (LightingNames :: any)[lightingPresetName]
		if not lightingPreset then
			warn(`'{lightingPresetName}' is not a valid lighting preset name.`)
			return
		end

		LightingSetter.readConfig(lightingPreset)
	end

	local cellsFolder = levelFolder:FindFirstChild("Cells")
	if not cellsFolder or not cellsFolder:IsA("Folder") then
		warn("Unable to initialize Cells: Cells folder not found in Level folder or is not a Folder.")
	else
		Level.initializeCells(cellsFolder)
	end

	local propsFolder = levelFolder:FindFirstChild("Props")
	if propsFolder and (propsFolder:IsA("Model") or propsFolder:IsA("Folder")) then
		Level.initializeClutters(propsFolder, (require :: any)(missionSetupModule).Colors)
	end

	local playerCollidersFolder = levelFolder:FindFirstChild("PlayerColliders")
	if playerCollidersFolder and playerCollidersFolder:IsA("Folder") then
		Level.initializePlayerColliders(playerCollidersFolder)
	end

	local barriersFolder = levelFolder:FindFirstChild("Barrier")
	if barriersFolder and barriersFolder:IsA("Folder") then
		Level.initializePlayerColliders(barriersFolder)
	end
end

function Level.initializePlayerColliders(folder: Folder): ()
	for _, part in ipairs(folder:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanTouch = false
		part.AudioCanCollide = false
		part.Anchored = true
		part.CollisionGroup = CollisionGroupTypes.PLAYER_COLLIDER
		part.Transparency = 1
	end
end

function Level.initializeClutters(levelPropsFolder: Model | Folder, colorsMap): ()
	local successfull = Clutter.initialize()
	if successfull then
		-- this is stupid as shit but we gotta.
		-- Luau you stupid bastard fix this shit, `placeholder` is of type `unknown`.

		-- TODO: If you cant see it already, this is bad. make it better.
		Clutter.replacePlaceholdersWithProps(levelPropsFolder, colorsMap, function(placeholder: BasePart, passed: boolean, prop: Model & { Base: BasePart })
			if passed and prop then
				for attName, v in pairs(placeholder:GetAttributes()) do
					prop:SetAttribute(attName, v)
				end
			end
			
			if placeholder.Name == "SpawnLocation" then
				local newSpawnLocation = Instance.new("SpawnLocation")
				local decal = newSpawnLocation:FindFirstChildOfClass("Decal")
				if decal then
					decal:Destroy()
				end
				newSpawnLocation.Anchored = true
				newSpawnLocation.CFrame = placeholder.CFrame
				newSpawnLocation.Size = placeholder.Size
				newSpawnLocation.Transparency = 1
				newSpawnLocation.CanCollide = false
				newSpawnLocation.CanQuery = false
				newSpawnLocation.CanTouch = false
				newSpawnLocation.AudioCanCollide = false
				newSpawnLocation.Parent = placeholder.Parent
				placeholder:Destroy()
				return true
			end

			if placeholder.Name == "DisguiseTrigger" then
				local disguiseName = placeholder:GetAttribute("Disguise") :: any
				if not disguiseName then
					error(`Failed to create disguise giver: On {placeholder:GetFullName()} placeholder does not have 'Disguise' attribute.`)
				end
				if type(disguiseName) ~= "string" then
					error(`Failed to create disguise giver: On {placeholder:GetFullName()} 'Disguise' attribute must be a string.`)
				end
				if disguiseName == "" then
					error(`Failed to create disguise giver: On {placeholder:GetFullName()} 'Disguise' is an empty string.`)
				end

				if not levelFolder then
					error("Level folder is nil wtf?")
				end

				local missionSetup = levelFolder:FindFirstChild("MissionSetup")
				if not missionSetup then
					error("MissionSetup doesnt exist in level folder.\nStrange. Should've been checked.") -- this will never happen.
				end

				missionSetup = (require)(missionSetup)
				local disguiseProfile = missionSetup.CustomDisguises[disguiseName]
				if not disguiseProfile then
					error(`'{disguiseName}' profile doesnt exist in MissionSetup.`)
				end

				-- im too lazy to add further checks.

				-- backwards compatibility with InfiltrationEngine:

				-- i think this should be on the client side but idfk.
				local localizedDisguiseName = missionSetup.CustomStrings[disguiseProfile.Name]
				local shirtId = disguiseProfile.Outfits[1][1]
				local pantsId = disguiseProfile.Outfits[1][2]

				-- For some reason, in InfiltrationEngine, the axis to make the
				-- prompt forward face is the positive X axis instead of the typical
				-- positive Z axis like LookVectors.

				local triggerAttachment = Instance.new("Attachment")
				triggerAttachment.Name = "Trigger"
				triggerAttachment.Parent = placeholder

				-- Position it half a unit along the placeholder's X axis
				local halfSize = placeholder.Size.X / 2

				-- Create a CFrame that positions AND orients the attachment
				-- Position: halfSize units along X axis (in object space)
				-- Orientation: Z axis faces along the placeholder's X axis (so -X direction in object space)
				triggerAttachment.CFrame = CFrame.new(-halfSize, 0, 0) * CFrame.lookAt(Vector3.zero, -Vector3.new(1, 0, 0))

				-- what the shit.
				local model = Instance.new("Model")
				model.Name = placeholder.Name
				model.PrimaryPart = placeholder
				model.Parent = placeholder.Parent

				local newDisguiser = PropDisguiseGiver.new(model, localizedDisguiseName, {
					Shirt = Content.fromAssetId(shirtId),
					Pants = Content.fromAssetId(pantsId)
				})

				newDisguiser:setupProximityPrompt()

				placeholder.Transparency = 1
				placeholder.CanCollide = false
				placeholder.CanQuery = false
				placeholder.CanTouch = false
				placeholder.AudioCanCollide = false
				return true
			end

			if placeholder:GetAttribute("Disguise") ~= nil and passed and prop then
				local disguiseName = placeholder:GetAttribute("Disguise") :: string
				if not levelFolder then
					error("Level folder is nil wtf?")
				end

				local missionSetup = levelFolder:FindFirstChild("MissionSetup")
				if not missionSetup then
					error("MissionSetup doesnt exist in level folder.\nStrange. Should've been checked.") -- this will never happen.
				end

				missionSetup = (require)(missionSetup)
				local disguiseProfile = missionSetup.CustomDisguises[disguiseName]
				if not disguiseProfile then
					error(`'{disguiseName}' profile doesnt exist in MissionSetup.`)
				end

				local localizedDisguiseName = missionSetup.CustomStrings[disguiseProfile.Name]
				local shirtId = disguiseProfile.Outfits[1][1]
				local pantsId = disguiseProfile.Outfits[1][2]

				local newDisguiser = PropDisguiseGiver.new(prop, localizedDisguiseName, {
					Shirt = Content.fromAssetId(shirtId),
					Pants = Content.fromAssetId(pantsId)
				}, disguiseProfile.BrickColor)

				newDisguiser:setupProximityPrompt()
				return true
			end

			if placeholder.Name == "FloatingFlatText" then
				placeholder:AddTag("Clutter")
				placeholder:SetAttribute("ClutterPropName", "FloatingFlatText")
				placeholder.Transparency = 1
				placeholder.CanCollide = false
				placeholder.CanQuery = false
				placeholder.CanTouch = false
				placeholder.AudioCanCollide = false
				return true
			end

			return false
		end)
	end
end

function Level.initializeCells(cellsFolder: Folder): ()
	for _, cellModel in ipairs(cellsFolder:GetChildren()) do
		if not cellModel:IsA("Model") then
			continue
		end

		--[[local cellName = cellModel.Name
		local cellConfig = Level.getCellConfig(cellName)
		local cframe, size = cellModel:GetBoundingBox()
		local areaName = cellModel:GetAttribute("AreaName") :: string?
		local bounds = { CFrame = cframe, Size = size, AreaName = areaName }
		Cell.addCell(cellName, bounds, cellConfig)]]

		if HIDE_CELLS then
			Level.hideCell(cellModel)
		end

		table.insert(cellsList, cellModel)
	end
end

function Level.getCellConfig(cellName: string): CellConfig.Config?
	return cellsConfig and cellsConfig[cellName] or nil
end

function Level.getCellModels(): {Model}
	return cellsList
end

function Level.hideCell(cellModel: Model): ()
	for _, cellChild in ipairs(cellModel:GetChildren()) do
		if not cellChild:IsA("BasePart") then
			continue
		end

		cellChild.Transparency = 1
		cellChild.CanCollide = false
		cellChild.CanQuery = false
		cellChild.CanTouch = false
		cellChild.AudioCanCollide = false
	end
end

function Level.showCell(cellModel: Model): ()
	for _, cellChild in ipairs(cellModel:GetChildren()) do
		if not cellChild:IsA("BasePart") then
			continue
		end

		cellChild.Transparency = DEBUG_MIN_CELLS_TRANSPARENCY
	end
end

function Level.update(deltaTime: number): ()
	timeAccum += deltaTime
	if timeAccum >= UPDATE_INTERVAL then
		timeAccum = 0
		Level.doUpdate(deltaTime)
	end
end

function Level.doUpdate(deltaTime: number): ()
	Level.updateCells()
end

function Level.updateCells(): ()
	Cell.update()
end

return Level