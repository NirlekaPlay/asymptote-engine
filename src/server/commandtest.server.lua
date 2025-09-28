--!nonstrict

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local INF = math.huge

type ArgumentType = ArgumentType.ArgumentType
type CommandContext<S> = CommandContext.CommandContext<S>
type CommandDispatcher<S> = CommandDispatcher.CommandDispatcher<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CommandFunction = CommandFunction.CommandFunction

--

local function boolean(): ArgumentType
	return BooleanArgumentType
end

local function integer(): ArgumentType
	return IntegerArgumentType
end

local function string(): ArgumentType
	return StringArgumentType
end

local function player(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			local selector = input:match("^@[apersme]") -- @a, @p, @e, @r, @s, @m, @e
			
			if selector then
				return {
					type = "selector",
					selector = selector
				}, selector:len()
			else
				-- Regular player name parsing
				local playerName = input:match("^%S+")
				if not playerName then
					error("Expected player name or selector")
				end
				
				local foundPlayer = nil
				for _, player in Players:GetPlayers() do
					if player.Name:lower():find(playerName:lower(), 1, true) == 1 or
					   player.DisplayName:lower():find(playerName:lower(), 1, true) == 1 then
						foundPlayer = player
						break
					end
				end
				
				if not foundPlayer then
					error("Player '" .. playerName .. "' not found")
				end
				
				return foundPlayer, playerName:len()
			end
		end
	}
end

local function resolvePlayerSelector(selectorData, source: Player): {Player}
	if type(selectorData) == "table" and selectorData.type == "selector" then
		local selector = selectorData.selector
		
		if selector == "@a" then
			return Players:GetPlayers() -- All players
		elseif selector == "@p" then
			-- Nearest player (simplified - just return first other player)
			local players = Players:GetPlayers()
			for _, player in players do
				if player ~= source then
					return {player}
				end
			end
			return {}
		elseif selector == "@s" then
			return {source} -- Self
		elseif selector == "@r" then
			-- Random player
			local players = Players:GetPlayers()
			if #players > 0 then
				return {players[math.random(#players)]}
			end
			return {}
		elseif selector == "@m" then
			local t = {}

			for _, inst in pairs(workspace:GetChildren()) do
				if inst:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(inst) then
					table.insert(t, inst)
				end
			end

			return t
		elseif selector == "@e" then
			local t = Players:GetPlayers()

			for _, inst in pairs(workspace:GetChildren()) do
				if inst:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(inst) then
					table.insert(t, inst)
				end
			end

			return t
		end
	else
		-- Regular player object
		return {selectorData}
	end
	
	return {}
end

local function preprocessJSON(jsonStr: string): string
	-- Match 'inf' that's not already in quotes
	-- This pattern looks for 'inf' that's preceded by : or [ or , and not already quoted
	jsonStr = jsonStr:gsub('([:%[,]%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	-- Handle inf at the start of values (after colons)
	jsonStr = jsonStr:gsub('(:%s*)inf(%s*[,%]}])', '%1"inf"%2')
	
	return jsonStr
end

local function json(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			-- Find JSON object starting with {
			if input:sub(1, 1) ~= "{" then
				error("Expected JSON object starting with '{'")
			end
			
			-- Simple bracket matching to find end of JSON
			local braceCount = 0
			local endPos = 0
			for i = 1, #input do
				local char = input:sub(i, i)
				if char == "{" then
					braceCount = braceCount + 1
				elseif char == "}" then
					braceCount = braceCount - 1
					if braceCount == 0 then
						endPos = i
						break
					end
				end
			end
			
			if endPos == 0 then
				error("Unterminated JSON object")
			end
			
			local jsonStr = input:sub(1, endPos)
			jsonStr = preprocessJSON(jsonStr)
			local success, jsonData = pcall(function()
				return HttpService:JSONDecode(jsonStr)
			end)
			
			if not success then
				error("Invalid JSON: " .. jsonData)
			end
			
			return jsonData, endPos
		end
	}
end

local function itemWithAttributes(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			-- Parse item name first
			local itemName = input:match("^%S+")
			if not itemName then
				error("Expected item name")
			end
			
			local consumed = itemName:len()
			local remaining = input:sub(consumed + 1)
			
			-- Check if there's JSON attributes
			remaining = remaining:match("^%s*(.*)") -- trim whitespace
			local attributes = nil
			
			if remaining and remaining:sub(1, 1) == "{" then
				local jsonArg = json()
				local attrData, jsonConsumed = jsonArg.parse(remaining)
				attributes = attrData
				consumed = consumed + (input:len() - remaining:len()) + jsonConsumed
			end
			
			return {
				itemName = itemName,
				attributes = attributes
			}, consumed
		end
	}
end

local function parseCoordinate(input: string): (CoordinateData?, number)
	-- Relative coordinate: ~5, ~-10, ~
	local relativeMatch = input:match("^~(%-?%d*)")
	if relativeMatch ~= nil then
		local offset = relativeMatch == "" and 0 or tonumber(relativeMatch)
		local consumed = 1 + #relativeMatch
		return {
			type = "relative",
			value = offset
		}, consumed
	end
	
	-- Local coordinate: ^5, ^-2, ^
	local localMatch = input:match("^%^(%-?%d*)")
	if localMatch ~= nil then
		local offset = localMatch == "" and 0 or tonumber(localMatch)
		local consumed = 1 + #localMatch
		return {
			type = "local", 
			value = offset
		}, consumed
	end
	
	-- Absolute coordinate: 10, -5, 0
	local absoluteMatch = input:match("^(%-?%d+%.?%d*)")
	if absoluteMatch then
		return {
			type = "absolute",
			value = tonumber(absoluteMatch)
		}, #absoluteMatch
	end
	
	return nil, 0
end

local function vec3(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			local remaining = input
			local coords = {}
			local totalConsumed = 0
			
			-- Parse 3 coordinates (x, y, z)
			for i = 1, 3 do
				-- Skip whitespace
				remaining = remaining:match("^%s*(.*)") or remaining
				
				-- Try to parse a coordinate (can be relative ~, absolute number, or local ^)
				local coord, consumed = parseCoordinate(remaining)
				if not coord then
					error(`Expected coordinate {i == 1 and "x" or i == 2 and "y" or "z"}`)
				end
				
				coords[i] = coord
				remaining = remaining:sub(consumed + 1)
				totalConsumed = totalConsumed + consumed
				
				-- Add whitespace consumption
				local whitespace = remaining:match("^(%s*)")
				if whitespace then
					remaining = remaining:sub(#whitespace + 1)
					totalConsumed = totalConsumed + #whitespace
				end
			end
			
			return {
				x = coords[1],
				y = coords[2], 
				z = coords[3]
			}, totalConsumed
		end
	}
end

export type CoordinateData = {
	type: "relative" | "absolute" | "local",
	value: number
}

export type Vec3Data = {
	x: CoordinateData,
	y: CoordinateData,
	z: CoordinateData
}

local function resolveVec3(vec3Data: Vec3Data, source: any): Vector3
	local sourcePos = Vector3.new(0, 0, 0)
	local sourceLook = Vector3.new(0, 0, -1) -- Forward direction
	local sourceRight = Vector3.new(1, 0, 0) -- Right direction
	local sourceUp = Vector3.new(0, 1, 0)    -- Up direction
	
	-- Get source position and orientation if it's a player
	if typeof(source) == "Instance" and source:IsA("Player") and source.Character then
		local character = source.Character
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			sourcePos = humanoidRootPart.Position
			sourceLook = humanoidRootPart.CFrame.LookVector
			sourceRight = humanoidRootPart.CFrame.RightVector  
			sourceUp = humanoidRootPart.CFrame.UpVector
		end
	end
	
	local function resolveCoord(coord: CoordinateData, currentPos: number, localAxis: Vector3): number
		if coord.type == "absolute" then
			return coord.value
		elseif coord.type == "relative" then
			return currentPos + coord.value
		elseif coord.type == "local" then
			-- Local coordinates are relative to entity's facing direction
			return currentPos + coord.value
		end
		return coord.value
	end
	
	return Vector3.new(
		resolveCoord(vec3Data.x, sourcePos.X, sourceRight),
		resolveCoord(vec3Data.y, sourcePos.Y, sourceUp), 
		resolveCoord(vec3Data.z, sourcePos.Z, sourceLook)
	)
end

--

local function getEntityPosition(entity): CFrame?
	if typeof(entity) == "Instance" and entity:IsA("Player") then
		local char = entity.Character
		return char and char.PrimaryPart and char.PrimaryPart.CFrame
	elseif typeof(entity) == "Instance" and entity:FindFirstChildOfClass("Humanoid") then
		return entity.PrimaryPart and entity.PrimaryPart.CFrame
	end
	return nil
end

local function teleportEntity(entity, targetCFrame: CFrame)
	if typeof(entity) == "Instance" and entity:IsA("Player") then
		local char = entity.Character
		if char then char:PivotTo(targetCFrame) end
	elseif typeof(entity) == "Instance" and entity:FindFirstChildOfClass("Humanoid") then
		entity:PivotTo(targetCFrame)
	end
end

--

local function literal(name: string): LiteralArgumentBuilder.LiteralArgumentBuilder
	return LiteralArgumentBuilder.new(name)
end

local function argument(name: string, argType: ArgumentType): RequiredArgumentBuilder.RequiredArgumentBuilder
	return RequiredArgumentBuilder.new(name, argType)
end

--

local dispatcher: CommandDispatcher<Player> = CommandDispatcher.new()

--[=[
	root
	├── teleport
	│   ├── <x> → <y> → <z> (coordinates)
	│   └── <player1>
	│       ├── <player2> (tp player1 to player2)
	│       └── [execute] (tp self to player1)
	├── kill
	│   ├── <target>
	│   └── [execute] (kill target)
	├── ?
	│   ├── [execute] (shows a list of commands)
	│   └── <command>
	│       └─── [execute] (shows the usage of that command)
]=]
local teleportNode = dispatcher:register(
	literal("teleport")
		:andThen(
			argument("location", vec3())
				:executes(function(c)
					local vec3Data = c:getArgument("location")
					local source = c:getSource()
					local targetPos = resolveVec3(vec3Data, source)
					
					local character = source.Character
					if character then
						character:PivotTo(CFrame.new(targetPos))
					end
					return 1
				end)
		)
		:andThen(
			argument("player1", player())
				:andThen(argument("player2", player())
					:executes(function(c)
						local targetData = c:getArgument("player2")
						local sourceData = c:getArgument("player1")
						local cmdSource = c:getSource()
						
						local targets = resolvePlayerSelector(targetData, cmdSource)
						local sources = resolvePlayerSelector(sourceData, cmdSource)
						
						if #targets == 0 then error("No target found") end
						if #sources == 0 then error("No source found") end
						
						local targetPos = getEntityPosition(targets[1])
						if not targetPos then error("Target has no valid position") end
						
						for _, source in sources do
							teleportEntity(source, targetPos)
						end
						
						return #sources
					end)
				)
				:executes(function(c)
					local targetData = c:getArgument("player1")
					local cmdSource = c:getSource()
					
					local targets = resolvePlayerSelector(targetData, cmdSource)
					if #targets == 0 then error("No target found") end
					
					local targetPos = getEntityPosition(targets[1])
					if not targetPos then error("Target has no valid position") end
					
					teleportEntity(cmdSource, targetPos)
					return 1
				end)
		)
)

dispatcher:register(
	literal("kill")
		:andThen(
			argument("targetPlayer", player())
				:executes(function(c)
					local selectorData = c:getArgument("targetPlayer")
					local source = c:getSource()
					local targets = resolvePlayerSelector(selectorData, source)
					
					for _, target in targets do
						local targetChar
						if target:IsA("Player") then
							targetChar = target.Character
						else
							targetChar = target
						end
						if targetChar then
							local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
							if humanoid then
								humanoid.Health = 0
								print("Killed " .. target.Name)
							end
						end
					end
					
					return #targets -- Return number of players affected
				end)
		)
)

local HIGHLIGHT_INST_NAME = "CmdHighlight"

dispatcher:register(
	literal("highlight")
		:andThen(
			argument("targetPlayer", player())
				:andThen(
					argument("bool", boolean())
						:executes(function(c)
							local flag = c:getArgument("bool") :: boolean
							local selectorData = c:getArgument("targetPlayer")
							local source = c:getSource()
							local targets = resolvePlayerSelector(selectorData, source)
							
							for _, target in targets do
								local targetChar
								if target:IsA("Player") then
									targetChar = target.Character
								else
									targetChar = target
								end
								
								if targetChar then
									local highlight = targetChar:FindFirstChild(HIGHLIGHT_INST_NAME) :: Highlight?
								
									if highlight then
										highlight.Enabled = flag
									elseif flag then
										local newHighlight = Instance.new("Highlight")
										newHighlight.Name = HIGHLIGHT_INST_NAME
										newHighlight.Adornee = targetChar
										newHighlight.Parent = targetChar
									end
								end
							end
							
							return #targets
						end)
				)
		)
)

local FORCE_FIELD_INST_NAME = "CmdForceField"

dispatcher:register(
	literal("forcefield")
		:andThen(
			literal("push")
				:andThen(
					argument("target", player())
						:executes(function(c)
							local selectorData = c:getArgument("target")
							local source = c:getSource()
							local targets = resolvePlayerSelector(selectorData, source)
							
							for _, target in targets do
								local targetChar
								if target:IsA("Player") then
									targetChar = target.Character
								else
									targetChar = target
								end
								
								if targetChar then
									local newForcefield = Instance.new("ForceField")
									newForcefield.Visible = true
									newForcefield.Name = FORCE_FIELD_INST_NAME
									newForcefield.Parent = targetChar
								end
							end
							
							return #targets
						end)
					:andThen(
						argument("ttl", integer())
							:executes(function(c)
								local ttl = c:getArgument("ttl")
								local selectorData = c:getArgument("target")
								local source = c:getSource()
								local targets = resolvePlayerSelector(selectorData, source)
								
								for _, target in targets do
									local targetChar
									if target:IsA("Player") then
										targetChar = target.Character
									else
										targetChar = target
									end
									
									if targetChar then
										local targetForceField = targetChar:FindFirstChild(FORCE_FIELD_INST_NAME)
										if not targetForceField or not targetForceField:IsA("ForceField") then
											local newForcefield = Instance.new("ForceField")
											newForcefield.Visible = true
											newForcefield.Name = FORCE_FIELD_INST_NAME
											newForcefield.Parent = targetChar
											targetForceField = newForcefield
										end
										
										Debris:AddItem(targetForceField, ttl)
									end
								end
								
								return #targets
							end)
					)
				)
		)
		:andThen(
			literal("pop")
				:andThen(
					argument("target", player())
						:executes(function(c)
							local selectorData = c:getArgument("target")
							local source = c:getSource()
							local targets = resolvePlayerSelector(selectorData, source)
							
							for _, target in targets do
								local targetChar
								if target:IsA("Player") then
									targetChar = target.Character
								else
									targetChar = target
								end
								
								if targetChar then
									local forceField = targetChar:FindFirstChildOfClass("ForceField")
									if forceField then
										forceField:Destroy()
									end
								end
							end
							
							return #targets
						end)
				)
		)
)

local TOOLS_PER_INST = {
	["fbb"] = ServerStorage.Tools["FB Beryl"],
	["bob_spawner"] = ServerStorage.Tools["Bob Spawner"],
	["c4"] = ReplicatedStorage.ExplFolder["Remote Explosive"]
} :: { [string]: Instance }

local ATTRIBUTE_HANDLERS = {
	fbb = {
		mags = function(item: Instance, value: any)
			item.settings.magleft.Value = value
		end,
		fireInterval = function(item: Instance, value: any)
			item.settings.speed.Value = value
		end,
		magCapacity = function(item: Instance, value: any)
			item.settings.maxmagcapacity.Value = value
		end,
	},
	c4 = {
		radius = function(item: Instance, value: any)
			require(item.Settings).ExpRange = value
		end,
		maxAmount = function(item: Instance, value: any)
			require(item.Settings).MaxAmmo = value
		end,
		amount = function(item: Instance, value: any)
			item.Handle:SetAttribute("Ammo", value)
		end,
		blastPressure = function(item: Instance, value: any)
			require(item.Settings).BlastPressure = value
		end,
		plantRange = function(item: Instance, value: any)
			require(item.Settings).PlantRange = value
		end,
	}
}

local function applyAttributes(item: Instance, itemName: string, attributes: {[string]: any})
	local handlers = ATTRIBUTE_HANDLERS[itemName]
	if not handlers or not attributes then return end
	
	for attrName, attrValue in pairs(attributes) do
		if attrValue == "inf" then
			attrValue = INF
		end
		local handler = handlers[attrName]
		if handler then
			handler(item, attrValue)
		else
			warn(`Unknown attribute '{attrName}' for item '{itemName}'`)
		end
	end
end

dispatcher:register(
	literal("give")
		:andThen(
			argument("targets", player())
				:andThen(
					argument("itemData", itemWithAttributes())
						:executes(function(c)
							local itemData = c:getArgument("itemData")
							local itemName = itemData.itemName
							local attributes = itemData.attributes
							
							local itemInst = TOOLS_PER_INST[itemName]
							if not itemInst then
								error(`'{itemName}' is not a valid item name`)
							end
							
							local selectorData = c:getArgument("targets")
							local source = c:getSource()
							local targets = resolvePlayerSelector(selectorData, source)

							for _, target in targets do
								if not target:IsA("Player") then continue end

								local itemClone = itemInst:Clone()
								
								if attributes then
									applyAttributes(itemClone, itemName, attributes)
								end
								
								itemClone.Parent = target.Backpack
							end
							
							return #targets
						end)
				)
		)
)

local NAMES_PER_ENTITIES = {
	bob = ServerStorage.REFERENCE_BOB,
	jeia = ServerStorage.REFERENCE_JEIA,
	envvy = ServerStorage.REFERENCE_ENVVY,
	andrew = ServerStorage.REFERENCE_ANDREW
}

dispatcher:register(
	literal("summon")
		:andThen(
			argument("name", string())
				:executes(function(c)
					local entityName = c:getArgument("name")
					local entityInst = NAMES_PER_ENTITIES[entityName] :: Model
					if not entityInst then
						error(`{entityName} is not a valid entity name`)
					end
					local playerSource = c:getSource() :: Player
					local playerChar = playerSource.Character
					local toCframe: CFrame

					if not playerChar then
						error("Player has no character")
					end

					toCframe = playerChar.PrimaryPart.CFrame

					local entityInstClone = entityInst:Clone()
					entityInstClone:PivotTo(toCframe)
					entityInstClone.Parent = workspace
				end)
		)
)

local helpNode = dispatcher:register(
	literal("?")
		:executes(function(c)
			local source = c:getSource()
			local availableCommands = dispatcher:getAllUsage(dispatcher.root, source, false)
			
			local helpText = "Available commands:\n"
			for i, command in ipairs(availableCommands) do
				helpText = helpText .. "/" .. command .. "\n"
			end
			
			-- Remove trailing newline
			helpText = helpText:sub(1, -2)
			
			TypedRemotes.ClientBoundChatMessage:FireClient(source, {
				literalString = helpText, 
				type = "plain"
			})
			
			return #availableCommands
		end)
		:andThen(
			argument("command", string())
				:executes(function(c)
					local source = c:getSource()
					local commandName = c:getArgument("command")
					
					local commandNode = dispatcher.root:getChild(commandName)
					if not commandNode then
						error(`'{commandName}' is not a valid command.`)
					end
					
					local commandsDetail = dispatcher:getAllUsage(commandNode, source, false)
					local helpText = `Command tree for '{commandName}':\n`
					for i, command in ipairs(commandsDetail) do
						helpText = helpText .. "/" .. commandName .. " " .. command .. "\n"
					end

					helpText = helpText:sub(1, -2)
					
					TypedRemotes.ClientBoundChatMessage:FireClient(source, {
						literalString = helpText, 
						type = "plain"
					})
				end)
		)
)

dispatcher:register(
	literal("help")
		:redirect(helpNode)
)

dispatcher:register(
	literal("tp")
		:redirect(teleportNode)
)

RestartServerCommand.register(dispatcher)
TagCommand.register(dispatcher)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)
