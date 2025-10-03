--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DestroyCommand = require(ServerScriptService.server.commands.DestroyCommand)
local ForceFieldCommand = require(ServerScriptService.server.commands.ForceFieldCommand)
local GiveCommand = require(ServerScriptService.server.commands.GiveCommand)
local HelpCommand = require(ServerScriptService.server.commands.HelpCommand)
local HighlightCommand = require(ServerScriptService.server.commands.HighlightCommand)
local KillCommand = require(ServerScriptService.server.commands.KillCommand)
local RestartServerCommand = require(ServerScriptService.server.commands.RestartServerCommand)
local SummonCommand = require(ServerScriptService.server.commands.SummonCommand)
local TagCommand = require(ServerScriptService.server.commands.TagCommand)
local TeleportCommand = require(ServerScriptService.server.commands.TeleportCommand)
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

type ArgumentType = ArgumentType.ArgumentType
type CommandContext<S> = CommandContext.CommandContext<S>
type CommandDispatcher<S> = CommandDispatcher.CommandDispatcher<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type CommandFunction = CommandFunction.CommandFunction

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



--

local dispatcher: CommandDispatcher<Player> = CommandDispatcher.new()

RestartServerCommand.register(dispatcher)
TagCommand.register(dispatcher)
KillCommand.register(dispatcher)
TeleportCommand.register(dispatcher)
HighlightCommand.register(dispatcher)
DestroyCommand.register(dispatcher)
ForceFieldCommand.register(dispatcher)
SummonCommand.register(dispatcher)
GiveCommand.register(dispatcher)
HelpCommand.register(dispatcher)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(str)
		local flag = str:sub(1, 1) == "/"
		if not flag then
			return
		end

		dispatcher:execute(str:sub(2), player)
	end)
end)
