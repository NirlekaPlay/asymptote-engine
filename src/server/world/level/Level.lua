--!strict

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterAppearancePayload = require(ReplicatedStorage.shared.network.payloads.CharacterAppearancePayload)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local BodyColorType = require(ReplicatedStorage.shared.network.types.BodyColorType)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local CollectionTagTypes = require(ServerScriptService.server.collection.CollectionTagTypes)
local PropDisguiseGiver = require(ServerScriptService.server.disguise.PropDisguiseGiver)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local LevelInstancesAccessor = require(ServerScriptService.server.world.level.LevelInstancesAccessor)
local PersistentInstanceManager = require(ServerScriptService.server.world.level.PersistentInstanceManager)
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)
local Clutter = require(ServerScriptService.server.world.level.clutter.Clutter)
local CardReader = require(ServerScriptService.server.world.level.clutter.props.CardReader)
local DoorCreator = require(ServerScriptService.server.world.level.clutter.props.DoorCreator)
local ItemSpawn = require(ServerScriptService.server.world.level.clutter.props.ItemSpawn)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local SoundSource = require(ServerScriptService.server.world.level.clutter.props.SoundSource)
local TriggerZone = require(ServerScriptService.server.world.level.clutter.props.triggers.TriggerZone)
local Mission = require(ServerScriptService.server.world.level.mission.Mission)
local MissionSetupReaderV1 = require(ServerScriptService.server.world.level.mission.reading.readers.MissionSetupReaderV1)
local ObjectiveManager = require(ServerScriptService.server.world.level.objectives.ObjectiveManager)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local LightingSetter = require(ServerScriptService.server.world.lighting.LightingSetter)

local INITIALIZE_NPCS_ONLY_WHEN_ENABLED = false
local HIDE_CELLS = true
local DEBUG_MIN_CELLS_TRANSPARENCY = 0.5
local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0

local levelFolder: Folder
local cellsList: { Model } = {}
local propsInLevelSet: { [Prop.Prop]: true } = {}
local propsInLevelSetThrottledUpdate: { [Prop.Prop]: true } = {}
local instancesParentedToNpcConfigs: { [Instance]: { [Instance]: true }} = {}
local guardCombatNodes: { Node.Node } = {}
local levelIsRestarting = false
local destroyNpcsCallback: () -> ()
local persistentInstMan = PersistentInstanceManager.new()
local cellManager: CellManager.CellManager
local levelInstancesAccessor: LevelInstancesAccessor.LevelInstancesAccessor
local charsAppearancePayloads: { [Model]: CharacterAppearancePayload.CharacterAppearancePayload } = {}
local objectiveManager: ObjectiveManager.ObjectiveManager = ObjectiveManager.new()
local globalVariablesObjs: { [string]: { parsed: ExpressionParser.ASTNode?, usedVariables: { [string]: true }}} = {}
local globalVariablesStatesChangedConn: RBXScriptConnection? = nil

function startsWith(mainString: string, startString: string)
	return string.match(mainString, "^" .. string.gsub(startString, "([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")) ~= nil
end

--[=[
	@class Level
]=]
local Level = {}

function Level.initializeLevel(): ()
	levelFolder = workspace:FindFirstChild("Level") :: Folder
	if not levelFolder or next(levelFolder:GetChildren()) == nil then
		levelFolder = workspace:FindFirstChild("DebugMission") :: Folder
	end
	if not levelFolder or not levelFolder:IsA("Folder") then
		warn("Unable to initialize Level: Level or DebugMission not found in Workspace or is not a Folder.")
		return
	end

	local missionSetupObj

	local missionSetupModule = levelFolder:FindFirstChild("MissionSetup") :: ModuleScript?
	if not missionSetupModule or not missionSetupModule:IsA("ModuleScript") then
		error("Unable to initialize Mission: MissionSetup module not found in Level folder or is not a ModuleScript.")
	else
		-- TODO: Use an actual centralized reader.
		missionSetupObj = MissionSetupReaderV1.parse(missionSetupModule)
	end

	local cellsFolder = levelFolder:FindFirstChild("Cells")
	if not cellsFolder or not cellsFolder:IsA("Folder") then
		warn("Unable to initialize Cells: Cells folder not found in Level folder or is not a Folder.")
	else
		Level.initializeCells(cellsFolder)
	end

	levelInstancesAccessor = LevelInstancesAccessor.new(
		missionSetupObj,
		cellsFolder and cellsFolder:GetChildren() :: { Model} or {},
		levelFolder:FindFirstChild("Nodes") :: Folder?
	)

	cellManager = CellManager.new(levelInstancesAccessor)

	if missionSetupObj:hasLightingSettings() then
		LightingSetter.readConfig(missionSetupObj:getLightingSettings())
	end

	-- Global variables

	local context = ExpressionContext.new(GlobalStatesHolder.getAllStatesReference(), true)

	if next(missionSetupObj.globalsExpressionStrs) ~= nil then -- SHOULD BE A METHOD!! TOO LAZY TO IMPLEMENT
		for varName, varExpr in missionSetupObj.globalsExpressionStrs do
			local parsed = ExpressionParser.fromString(varExpr):parse()
			local evaluated = if parsed == nil then true else ExpressionParser.evaluate(parsed, context)
			local usedVars = if parsed then ExpressionParser.getVariablesSet(parsed) else {}
			globalVariablesObjs[varName] = {
				parsed = parsed,
				usedVariables = usedVars
			}
			GlobalStatesHolder.setState(varName, evaluated)
		end
	end

	globalVariablesStatesChangedConn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(stateName, stateValue)
		--print(stateName, stateValue)
		--print(GlobalStatesHolder.getAllStatesReference())
		for varName, data in globalVariablesObjs do
			if data.usedVariables[stateName] then
				if data.parsed then
					local newValue = ExpressionParser.evaluate(data.parsed, context)
					if GlobalStatesHolder.getState(varName) ~= newValue then
						GlobalStatesHolder.setState(varName, newValue)
					end
				end
			end
		end
	end)

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

	local npcsFolder = levelFolder:FindFirstChild("Bots") or levelFolder:FindFirstChild("Npcs")
	if npcsFolder then
		local stack = {npcsFolder}
		local index = 1

		while index > 0 do
			local current = stack[index]
			stack[index] = nil
			index = index - 1

			if (current:IsA("BoolValue") and not (INITIALIZE_NPCS_ONLY_WHEN_ENABLED and not current.Value)) or current:IsA("Configuration") then
				-- NOTES: This might create problems. Oh well.
				-- TODO: Oh and by the way MAYBEEEEE the accessories bullshit should be
				-- on the client side.
				task.spawn(Level.initializeNpc, current)
			end

			if current:IsA("Folder") then
				local children = current:GetChildren()
				for i = #children, 1, -1 do
					index = index + 1
					stack[index] = children[i]
				end
			end
		end
	end

	-- Objectives

	objectiveManager:fromMissionSetupTable(missionSetupObj:getObjectives())
end

-- TODO: THIS SHIT TOO.
local RIG_TO_CLONE = ReplicatedStorage.shared.assets.characters.Rig
local OUTFITS = {
	["PsdPlainColourable"] = { 4893820412, 4893808612 },
	["PsdPlain"] = { 4893814518, 4893808612 }
} :: { [string]: { number } }

local function applyBodyColors(bodyColorsInst: BodyColors, bodyColors: BodyColorType.BodyColorType): ()
	-- ROBLOX FIX YOUR SHIT
	-- I SWEAR TO GOD THE LIMB COLORS ARE NOT SET
	-- AND YES THE ACTUAL COLOR PROPERTIES OF THE BODY COLORS INSTANCE ARE SET CORRECTLY
	-- BUT NOOOO THE FUCKING LIMB COLORS ARE NOT UPDATED, ONLY IF I FUCKING MANUALLY CHANGE
	-- A COLOR PROPERTY OF THE BODY COLORS INSTANCE FROM THE EDITOR **THEN** THE LIMB COLORS
	-- CHANGES. BUT EVEN WITH THAT BULLSHIT THE HEAD COLOR IS STILL FUCKING GRAY
	-- EVEN THOUGH THE COLOR PROPERTY OF THE HEAD IS SET.
	-- WHAT IN THE RETARDED ASS FUCK IS THIS?!??!?!?!
	bodyColorsInst.HeadColor3 = bodyColors.HeadColor
	bodyColorsInst.LeftArmColor3 = bodyColors.LeftArmColor
	bodyColorsInst.RightArmColor3 = bodyColors.RightArmColor
	bodyColorsInst.LeftLegColor3 = bodyColors.LeftLegColor
	bodyColorsInst.RightLegColor3 = bodyColors.RightLegColor
	bodyColorsInst.TorsoColor3 = bodyColors.TorsoColor
end

function Level.initializeNpc(inst: Instance): ()
	-- TODO: SOMEONE FUCKING FIX THIS BULLSHIT THANK YOU
	-- whats worse is this shit is initialized in Server sever script so theres no way to access it
	-- so the only we is to add a tag to it and write a small refactor on the script
	-- too fucking fucked to write a seperate npcs manager and turning the server into a module script
	-- creates a circular dependency bullshit.

	-- TODO: Apperance of the NPC or some shit.
	local nodes = inst:GetAttribute("Nodes")
	if not nodes then
		warn(`Looks like we cannot spawn '{inst.Name}' (which is located in {inst:GetFullName()}) as it does not have a Nodes attribute, we cannot spawn it anywhere!`)
		return
	end
	if type(nodes) ~= "string" then
		warn(`Error while trying to spawn NPCs: {inst:GetFullName()}: Nodes must be a string that points to a group of nodes!`)
		return
	end
	local charName = inst:GetAttribute("CharName") :: string?

	local seed =( inst:GetAttribute("Seed") or tick() ) :: number
	local rng = Random.new(seed)

	local nodesFolder
	if not levelInstancesAccessor:getNodesFolder() then
		warn(`Error while trying to spawn NPCs: {inst:GetFullName()}: Cannot initialise node group as 'Nodes' folder is not set!`)
		return
	else
		nodesFolder = (levelInstancesAccessor:getNodesFolder() :: Folder):FindFirstChild(nodes, true)
	end
	if not nodesFolder then
		warn(`Error while trying to spawn NPCs: {inst:GetFullName()}: Node group '{nodes}' not found!`)
		return
	end
	local nodesFolderChildren = nodesFolder:GetChildren()
	if next(nodesFolderChildren) == nil then
		warn(`Error while trying to spawn NPCs: {inst:GetFullName()}: Node group '{nodes}' is empty!`)
		return
	end

	-- TODO: Whats even more worse is that this will fuck shit up if we have multiple NPCs
	-- in the same node group.
	local nodesArray: { BasePart } = {}
	local nodesCount = 0

	-- all descendant nodes of the folder are all part of a singular node.
	local stack = nodesFolderChildren
	local index = 1

	while index > 0 do
		local current = stack[index]
		stack[index] = nil
		index = index - 1

		if current:IsA("BasePart") and current.Name == "Node" then
			nodesCount += 1
			nodesArray[nodesCount] = current
		end

		if current:IsA("Folder") then
			local children = current:GetChildren()
			for i = #children, 1, -1 do
				index = index + 1
				stack[index] = children[i]
			end
		end
	end

	local selectedRandomNode = nodesArray[rng:NextInteger(1, nodesCount)] :: BasePart
	local nodeCframe = selectedRandomNode.CFrame

	local characterRigClone = RIG_TO_CLONE:Clone()
	characterRigClone.Name = inst.Name

	local charAppSeed = tonumber(inst:GetAttribute("CharAppSeed") :: (string | number)?) or tick()
	if charAppSeed then
		-- char shit.
	end

	local outfitName = inst:GetAttribute("Outfit") :: string?
	if (outfitName and OUTFITS[outfitName] == nil) then
		warn(`It seems like the outfit '{outfitName}' doesnt exist!`)
	elseif (outfitName and OUTFITS[outfitName]) then
		local shirt = Instance.new("Shirt")
		shirt.ShirtTemplate = "rbxassetid://" .. OUTFITS[outfitName][1]
		local pants = Instance.new("Pants")
		pants.PantsTemplate = "rbxassetid://" .. OUTFITS[outfitName][2] -- we're still doing this shit arent we?

		shirt.Parent = characterRigClone
		pants.Parent = characterRigClone
	end

	local skinColor = inst:GetAttribute("SkinColor") :: (Color3 | BrickColor)?
	if not skinColor then
		skinColor = BrickColor.new("Pastel brown")
	end

	local skinColor3: Color3

	if typeof(skinColor) == "BrickColor" then
		skinColor3 = skinColor.Color
	else
		skinColor3 = skinColor :: Color3
	end
	
	local bodyColors: BodyColorType.BodyColorType = {
		HeadColor = skinColor3,
		LeftArmColor = skinColor3,
		RightArmColor = skinColor3,
		LeftLegColor = skinColor3,
		RightLegColor = skinColor3,
		TorsoColor = skinColor3
	}

	local upperBodyColor = inst:GetAttribute("UpperBodyColor") :: (Color3 | BrickColor)?
	if upperBodyColor then
		-- ok not so racist
		-- maybe sun burns
		local bodyColorsInst = characterRigClone:FindFirstChild("Body Colors")
		if not bodyColorsInst then
			warn("Body Colors instance not found in character rig clone!")
			return
		end

		local upperBodyColor3: Color3

		if typeof(upperBodyColor) == "BrickColor" then
			upperBodyColor3 = upperBodyColor.Color
		elseif typeof(upperBodyColor) == "Color3" then
			upperBodyColor3 = upperBodyColor
		end

		bodyColors.LeftArmColor = upperBodyColor3
		bodyColors.RightArmColor = upperBodyColor3
		bodyColors.TorsoColor = upperBodyColor3
	end

	-- TODO: For accessories, maybe just parent the accesorries to the instance
	-- OR have number values instance as its children under the instance,
	-- that way we can have both the name of the accessory AND the asset id.
	local index = 0
	while true do
		local assetId = inst:GetAttribute("Asset" .. index)
		if assetId == nil then
			break -- no more attributes
		end

		if type(assetId) ~= "number" then
			warn(("Invalid Asset%d attribute: expected number, got %s"):format(index, typeof(assetId)))
			break
		end

		local success, model: Instance = (pcall :: any)(InsertService.LoadAsset, InsertService, assetId)
		if not success then
			warn("An error occured while trying to fetch asset: ", model)
		else
			for _, child in model:GetChildren() do
				child.Parent = characterRigClone
			end

			index += 1
		end
	end

	if instancesParentedToNpcConfigs[inst] then
		for child in instancesParentedToNpcConfigs[inst] do
			local childClone = child:Clone()
			childClone.Parent = characterRigClone
		end
	else
		for _, child in inst:GetChildren() do
			if not instancesParentedToNpcConfigs[inst] then
				instancesParentedToNpcConfigs[inst] = {}
			end

			instancesParentedToNpcConfigs[inst][child] = true

			child.Parent = nil

			local childClone = child:Clone()
			childClone.Parent = characterRigClone
		end
	end

	local offsetPosition = nodeCframe.Position
	characterRigClone:PivotTo(CFrame.new(offsetPosition, offsetPosition + nodeCframe.LookVector))

	-- Works on the fucking server what the fuck.
	applyBodyColors(characterRigClone:FindFirstChildOfClass("BodyColors"), bodyColors)
	characterRigClone.Parent = workspace
	characterRigClone:SetAttribute("Seed", seed)
	characterRigClone:SetAttribute("Nodes", nodes)
	characterRigClone:SetAttribute("CharName", charName)
	if inst:GetAttribute("EnforceClass") then
		characterRigClone:SetAttribute("EnforceClass", inst:GetAttribute("EnforceClass"))
	end
	characterRigClone:AddTag(CollectionTagTypes.NPC_DETECTION_DUMMY.tagName) -- this aint a dummy no more

	local payload: CharacterAppearancePayload.CharacterAppearancePayload = {
		character = characterRigClone,
		bodyColors = bodyColors
	}

	charsAppearancePayloads[characterRigClone] = payload

	TypedRemotes.ClientBoundCharacterAppearances:FireAllClients({payload})

	characterRigClone.Destroying:Once(function()
		charsAppearancePayloads[characterRigClone] = nil
	end)
end

function Level.onPlayerJoined(player: Player): ()
	if next(charsAppearancePayloads) ~= nil then
		local charAppearancesPayloads: { CharacterAppearancePayload.CharacterAppearancePayload } = {}
		local i = 0
		for char, payload in charsAppearancePayloads do
			i = 1
			charAppearancesPayloads[i] = payload
		end
		TypedRemotes.ClientBoundCharacterAppearances:FireClient(player, charAppearancesPayloads)
	end

	objectiveManager:sendCurrentObjectivesToPlayer(player)
end

function Level.initializePlayerColliders(folder: Folder): ()
	for _, part in ipairs(folder:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		Level.initializePlayerCollider(part)
	end
end

function Level.initializePlayerCollider(part: BasePart): ()
	part.CanTouch = false
	part.AudioCanCollide = false
	part.Anchored = true
	part.CollisionGroup = CollisionGroupTypes.PLAYER_COLLIDER
	part.Transparency = 1
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
					prop:SetAttribute(attName, v);
					(prop :: any).Base:SetAttribute(attName, v)
				end

				(prop :: any).Base.Size = placeholder.Size
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

				local newDisguiser = PropDisguiseGiver.new(model, disguiseName, localizedDisguiseName, {
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
				if disguiseName == "" then
					warn(`The Disguise attribute of {placeholder:GetFullName()} is an empty string.`)
					return false
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

				local localizedDisguiseName = missionSetup.CustomStrings[disguiseProfile.Name]
				local shirtId = disguiseProfile.Outfits[1][1]
				local pantsId = disguiseProfile.Outfits[1][2]

				local newDisguiser = PropDisguiseGiver.new(prop, disguiseName, localizedDisguiseName, {
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

			if placeholder.Name == "SoundSource" then
				propsInLevelSet[SoundSource.createFromPlaceholder(placeholder)] = true
				return true
			end

			if placeholder.Name == "GuardCombatNode" then
				placeholder.Transparency = 1
				placeholder.CanCollide = false
				placeholder.CanQuery = false
				placeholder.CanTouch = false
				placeholder.AudioCanCollide = false
				table.insert(guardCombatNodes, Node.fromPart(placeholder))
				return true
			end

			if placeholder.Name == "PlayerCollider" then
				Level.initializePlayerCollider(placeholder)
				return true
			end

			if placeholder.Name == "CardReader" and passed then
				CardReader.createFromModel(prop)
				return true
			end

			if startsWith(placeholder.Name, "Door") and passed and prop then
				propsInLevelSet[DoorCreator.createFromPlaceholder(placeholder, prop)] = true
				return true
			end

			if placeholder.Name == "ItemSpawn" then
				propsInLevelSet[ItemSpawn.createFromPlaceholder(placeholder, nil, Level)] = true
				return true
			end

			if placeholder.Name == "TriggerZone" then
				propsInLevelSetThrottledUpdate[TriggerZone.createFromPlaceholder(placeholder, nil, Level)] = true
				return true
			end

			return false
		end)
	end
end

function Level.isRestarting(): boolean
	return levelIsRestarting
end

function Level.getPersistentInstanceManager(_): PersistentInstanceManager.PersistentInstanceManager
	return persistentInstMan
end

function Level.getGuardCombatNodes(): { Node.Node }
	return guardCombatNodes
end

function Level.initializeCells(cellsFolder: Folder): ()
	for _, cellModel in ipairs(cellsFolder:GetChildren()) do
		if not cellModel:IsA("Model") then
			continue
		end

		if HIDE_CELLS then
			Level.hideCell(cellModel)
		end

		table.insert(cellsList, cellModel)
	end
end

function Level.getServerLevelInstancesAccessor(_): LevelInstancesAccessor.LevelInstancesAccessor
	return levelInstancesAccessor
end

function Level.getCellModels(): {Model}
	return cellsList
end

function Level.getCellManager(_): CellManager.CellManager
	return cellManager
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

function Level.restartLevel(): ()
	if Level.isRestarting() then
		return
	end

	levelIsRestarting = true

	task.wait()

	for prop in propsInLevelSet do
		prop:onLevelRestart()
	end

	print("Variables after prop resets:", GlobalStatesHolder.getAllStatesReference())

	local registeredGlobals = levelInstancesAccessor:getMissionSetup().globalsExpressionStrs
	GlobalStatesHolder.resetAllStates(function(stateName)
		return true --registeredGlobals[stateName] ~= nil
	end)

	if next(registeredGlobals) ~= nil then
		for varName, varExpr in levelInstancesAccessor:getMissionSetup().globalsExpressionStrs do
			GlobalStatesHolder.setState(varName, ExpressionParser.parseAndEvalute(varExpr, Level:getExpressionContext()))
		end
	end

	print("Variables after global resets:", GlobalStatesHolder.getAllStatesReference())

	Mission.resetAlertLevel()

	for _, player in Players:GetPlayers() do
		local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if statusHolder then
			statusHolder:clearAllStatuses()
		end
		player:LoadCharacter()
	end

	if destroyNpcsCallback then
		destroyNpcsCallback()
	end

	persistentInstMan:destroyAll()

	local npcsFolder = levelFolder:FindFirstChild("Bots") or levelFolder:FindFirstChild("Npcs")
	if npcsFolder then
		local stack = {npcsFolder}
		local index = 1

		while index > 0 do
			local current = stack[index]
			stack[index] = nil
			index = index - 1

			if (current:IsA("BoolValue") and not (INITIALIZE_NPCS_ONLY_WHEN_ENABLED and not current.Value)) or current:IsA("Configuration") then
				task.spawn(Level.initializeNpc, current)
			end

			if current:IsA("Folder") then
				local children = current:GetChildren()
				for i = #children, 1, -1 do
					index = index + 1
					stack[index] = children[i]
				end
			end
		end
	end

	task.wait(1)

	levelIsRestarting = false

	print(GlobalStatesHolder.getAllStatesReference())
end

function Level.setDestroyNpcsCallback(f: () -> ()): ()
	destroyNpcsCallback = f
end

function Level.update(deltaTime: number): ()
	Level.onSimulationStepped(deltaTime)

	timeAccum += deltaTime

	while timeAccum >= UPDATE_INTERVAL do
		Level.doUpdate(UPDATE_INTERVAL)
		timeAccum -= UPDATE_INTERVAL
	end
end

function Level.onSimulationStepped(deltaTime: number): ()
	persistentInstMan:update(deltaTime)
	Level.updateProps(deltaTime)
end

-- its a reference so I guess we dont need to change anything????
local context = ExpressionContext.new(GlobalStatesHolder.getAllStatesReference()) 

function Level.doUpdate(deltaTime: number): ()
	Level.updateCells()
	for prop in propsInLevelSetThrottledUpdate do
		prop:update(deltaTime, Level)
	end
	objectiveManager:update(context)
end

function Level.getExpressionContext(_): ExpressionContext.ExpressionContext
	return context
end

function Level.updateProps(deltaTime: number): ()
	for prop in propsInLevelSet do
		prop:update(deltaTime, Level)
	end
end

function Level.updateCells(): ()
	cellManager:update()
end

return Level