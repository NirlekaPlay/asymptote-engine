--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
			local selector = input:match("^@[apers]") -- @a, @p, @e, @r, @s
			
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
		end
	else
		-- Regular player object
		return {selectorData}
	end
	
	return {}
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
						local playerTarget = c:getArgument("player2") :: Player
						local playerSource = c:getArgument("player1")

						local playerCharacter = (playerSource :: Player).Character
						if not playerCharacter then
							error("Player has no Character.")
						end

						local targetCharacter = playerTarget.Character
						if not targetCharacter then
							error("Target player has no Character.")
						end

						playerCharacter:PivotTo(targetCharacter.PrimaryPart.CFrame)

						return 1
					end)
				)
				:executes(function(c)
					local playerTarget = c:getArgument("player1") :: Player
					local playerSource = c:getSource()

					local playerCharacter = (playerSource :: Player).Character
					if not playerCharacter then
						error("Player has no Character.")
					end

					local targetCharacter = playerTarget.Character
					if not targetCharacter then
						error("Target player has no Character.")
					end

					playerCharacter:PivotTo(targetCharacter.PrimaryPart.CFrame)

					return 1
				end
			)
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
						local targetChar = target.Character
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

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)
