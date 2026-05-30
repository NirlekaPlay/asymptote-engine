--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local UString = require(ReplicatedStorage.shared.util.string.UString)
local LevelAccessor = require(ReplicatedStorage.shared.world.level.LevelAccessor)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local MissionSetupReader = require(ServerScriptService.server.world.level.mission.reading.MissionSetupReader)
local PropRegistry = require(ServerScriptService.server.world.level.props.registry.PropRegistry)
local Scene = require(ServerScriptService.server.world.level.scene.Scene)
local Clutter = require(ServerScriptService.server.world.level.scene.props.Clutter)

--[=[
	@class SceneManager
]=]
local SceneManager = {}
SceneManager.__index = SceneManager

export type SceneManager = typeof(setmetatable({} :: {
	currentScene: Scene?,
	level: LevelAccessor.LevelAccessor,
	isLoading: boolean
}, SceneManager))

type Scene = Scene.Scene

function SceneManager.new(level: LevelAccessor.LevelAccessor): SceneManager
	return setmetatable({
		currentScene = nil :: Scene?,
		level = level,
		isLoading = false
	}, SceneManager)
end

--

function SceneManager.update(self: SceneManager, deltaTime: number): ()
	if self.currentScene then
		self.currentScene:update(deltaTime)
	end
end

--

function SceneManager.isLoading(self: SceneManager): boolean
	return self.isLoading
end

function SceneManager.getActiveScene(self: SceneManager): Scene?
	return self.currentScene
end

function SceneManager.clear(self: SceneManager): ()
	local currentLevelFolder = workspace:FindFirstChild("DebugMission") or workspace:FindFirstChild("Level")
	if currentLevelFolder and currentLevelFolder:IsA("Folder") then
		currentLevelFolder:Destroy()
	end

	if not self.currentScene then
		return
	end

	self.currentScene:clear()
	self.currentScene = nil
end

function SceneManager.loadScene(self: SceneManager, sceneName: string): ()
	local sceneFolder = self:_getMapsFolder():FindFirstChild(sceneName) :: Instance?
	if not sceneFolder or not sceneFolder:IsA("Folder") then
		error(`Failed to load scene '{sceneName}': No such scene`)
	end

	self:loadSceneFromFolder(sceneFolder)
end

function SceneManager.restartScene(self: SceneManager): ()
	if self:isSceneRestarting() then
		return
	end

	self.currentScene:restart()
end

function SceneManager.isSceneRestarting(self: SceneManager): boolean
	if not self.currentScene then
		return false
	end

	return self.currentScene:isRestarting()
end

function SceneManager.getMapList(self: SceneManager): {string}
	local list: {string} = {}
	for _, map in self:_getMapsFolder():GetChildren() :: {Instance} do
		if map:IsA("Folder") then
			table.insert(list, map.Name)
		end
	end

	return list
end

function SceneManager._getMapsFolder(self: SceneManager): Folder
	local mapFolder = ServerStorage:FindFirstChild("Maps")
	if not mapFolder or not mapFolder:IsA("Folder") then
		error(`Cannot fetch maps: 'Maps' folder not present in 'ServerStorage'`)
	end

	return mapFolder
end

--

function SceneManager.loadSceneFromFolder(self: SceneManager, folder: Folder): ()
	if self.isLoading then
		warn(`Attempt to load scene '{folder.Name}' while already loading another scene`)
		return
	end

	self.isLoading = true

	self:clear()
	local workingSceneFolder = folder:Clone()
	workingSceneFolder.Name = "DebugMission"
	workingSceneFolder.Parent = workspace

	local missionSetupObj = self:getAndParseMissionSetupModule(workingSceneFolder)
	local cellsConfigs = missionSetupObj.cells
	local cellsFolder = workingSceneFolder:FindFirstChild("Cells")
	if cellsFolder and not cellsFolder:IsA("Folder") then
		cellsFolder = nil
	end

	local cells = self:createCellsFromFolder(cellsConfigs, cellsFolder)

	local newScene = Scene.new(cells, missionSetupObj)

	local propsFolder = workingSceneFolder:FindFirstChild("Props")
	if propsFolder and propsFolder:IsA("Folder") then
		self:initializeProps(propsFolder, missionSetupObj, newScene)
	end

	local nodesFolder = folder:FindFirstChild("Nodes")
	if nodesFolder and nodesFolder:IsA("Folder") then
		newScene.navMesh:setPostsFromFolder(nodesFolder)
	end

	local npcsFolder = folder:FindFirstChild("Bots") or folder:FindFirstChild("Npcs")
	if npcsFolder and npcsFolder:IsA("Folder") then
		local function initNpc(inst: BoolValue): ()
			self.level:addFreshEntity()
		end

		local function parseNpcs(folder: Folder): ()
			for _, child in folder:GetChildren() do
				if child:IsA("BoolValue") then
					initNpc(child)
				else
					parseNpcs(folder)
				end
			end
		end

		parseNpcs(npcsFolder)
	end

	self.currentScene = newScene

	self.isLoading = false
end

function SceneManager.getAndParseMissionSetupModule(self: SceneManager, sceneFolder: Folder)
	local missionSetupModule = sceneFolder:FindFirstChild("MissionSetup") :: ModuleScript?
	if not missionSetupModule or not missionSetupModule:IsA("ModuleScript") then
		error("Unable to initialize Mission: MissionSetup module not found in Level folder or is not a ModuleScript.")
	else
		return MissionSetupReader.read(missionSetupModule)
	end
end

function SceneManager.initializeProps(self: SceneManager, propsFolder: Folder, missionSetupObj, newScene: Scene): ()
	local function proccessPlaceholders(placeholder: BasePart, passed: boolean, prop: Model & { Base: BasePart }): boolean
		if passed and prop then
			for attName, v in pairs(placeholder:GetAttributes()) do
				prop:SetAttribute(attName, v);
				(prop :: any).Base:SetAttribute(attName, v)
			end

			(prop :: any).Base.Size = placeholder.Size

			local tagAtt = prop:GetAttribute("Tag")
			if tagAtt and type(tagAtt) == "string" and not UString.isBlank(tagAtt) then
				prop:AddTag(tagAtt)
			end

			local turnTransparent = prop:GetAttribute("Transparent") == true
			if turnTransparent then
				for _, child in prop:GetDescendants() do
					if child:IsA("BasePart") then
						child.Transparency = 1
					end
				end
			end
		else
			local tagAtt = placeholder:GetAttribute("Tag")
			if tagAtt and type(tagAtt) == "string" and not UString.isBlank(tagAtt) then
				placeholder:AddTag(tagAtt)
			end
		end

		local handler = PropRegistry.getHandler(placeholder.Name)
		if handler then
			local success, returnedProp = handler:proccess(placeholder, prop, newScene)
			if returnedProp then
				newScene.propManager:addProp(returnedProp)
			end

			if success then
				return true
			end
		end

		return false
	end

	Clutter.replacePlaceholdersWithProps(
		propsFolder,
		missionSetupObj.colors,
		newScene:getExpressionContext(),
		proccessPlaceholders
	)
end

function SceneManager.createCellsFromFolder(self: SceneManager, parsedConfigs, cellsFolder: Folder?): {Cell.Cell}
	local cells: {Cell.Cell} = {}

	if not cellsFolder then
		return cells
	end

	for _, cellModel in cellsFolder:GetChildren() do
		local cell = {}
		cell.name = cellModel.Name
		cell.hasFloor = cellModel:FindFirstChild("Floor") ~= nil
		cell.locationStr = cellModel:GetAttribute("Location") :: string?
		cell.config = parsedConfigs[cellModel.Name] and parsedConfigs[cellModel.Name].config or nil

		local bounds = {}
		local boundsI = 0
		for _, part in cellModel:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end

			local type = part.Name
			if type ~= "Floor" and type ~= "Roof" then
				continue
			end

			local bound = {}
			bound.cframe = part.CFrame
			bound.size = part.Size
			bound.type = if type == "Floor" then Cell.BoundType.FLOOR else Cell.BoundType.ROOF

			boundsI += 1
			bounds[boundsI] = bound
		end

		cell.bounds = bounds
		table.insert(cells, cell)
	end

	return cells
end

return SceneManager