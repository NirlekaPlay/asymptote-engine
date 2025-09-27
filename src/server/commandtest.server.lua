--!nonstrict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local CommandFunction = require(ReplicatedStorage.shared.commands.CommandFunction)
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)

type ArgumentType = ArgumentType.ArgumentType
type CommandContext = CommandContext.CommandContext
type CommandDispatcher = CommandDispatcher.CommandDispatcher
type CommandNode = CommandNode.CommandNode
type CommandFunction = CommandFunction.CommandFunction

-- Argument Types
local function integer(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			local num = tonumber(input:match("^%-?%d+"))
			if num then
				local len = tostring(math.floor(num)):len()
				if input:sub(1, 1) == "-" then len += 1 end
				return num, len
			end
			error("Expected integer, got: " .. input)
		end
	}
end

local function string(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			local word = input:match("^%S+")
			if word then
				return word, word:len()
			end
			error("Expected string argument")
		end
	}
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
				if inst:FindFirstChildOfClass("Humanoid") then
					table.insert(t, inst)
				end
			end

			return t
		elseif selector == "@e" then
			local t = Players:GetPlayers()

			for _, inst in pairs(workspace:GetChildren()) do
				if inst:FindFirstChildOfClass("Humanoid") then
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

local function boolean(): ArgumentType
	return {
		parse = function(input: string): (any, number)
			local word = input:match("^%S+"):lower()
			
			if word == "true" then
				return true, 4
			elseif word == "false" then
				return false, 5
			else
				error("Expected 'true' or 'false', got: " .. word)
			end
		end
	}
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

local dispatcher: CommandDispatcher = CommandDispatcher.new()

--[=[
	root
	├── teleport
	│   ├── <x> → <y> → <z> (coordinates)
	│   └── <player1>
	│       ├── <player2> (tp player1 to player2)
	│       └── [execute] (tp self to player1)
	└── kill
		├── <target>
		└── [execute] (kill target)
]=]
dispatcher:register(
	literal("teleport")
		:andThen(
			argument("x", integer())
				:andThen(
					argument("y", integer())
						:andThen(
							argument("z", integer())
								:executes(function(c)
									local x = c:getArgument("x")
									local y = c:getArgument("y") 
									local z = c:getArgument("z")
									local playerSource = c:getSource()

									local playerCharacter = (playerSource :: Player).Character
									if not playerCharacter then
										error("Player has no Character.")
									end

									-- what the fuck.
									local cf2 = playerCharacter.PrimaryPart.CFrame
									local posSource = CFrame.new(x, y, z)
									local oriSource = CFrame.new(0, 0, 0,
										cf2.XVector.X, cf2.YVector.X, cf2.ZVector.X,
										cf2.XVector.Y, cf2.YVector.Y, cf2.ZVector.Y,
										cf2.XVector.Z, cf2.YVector.Z, cf2.ZVector.Z
									)
									playerCharacter:PivotTo(posSource * oriSource)

									return 1
								end)
						)
				)
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
	}
}

local function applyAttributes(item: Instance, itemName: string, attributes: {[string]: any})
	local handlers = ATTRIBUTE_HANDLERS[itemName]
	if not handlers or not attributes then return end
	
	for attrName, attrValue in pairs(attributes) do
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

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)
