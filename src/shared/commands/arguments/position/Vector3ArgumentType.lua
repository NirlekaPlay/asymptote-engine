--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local Suggestions = require(ReplicatedStorage.shared.commands.suggestion.Suggestions)
local SuggestionsBuilder = require(ReplicatedStorage.shared.commands.suggestion.SuggestionsBuilder)
local CompletableFuture = require(ReplicatedStorage.shared.commands.util.CompletableFuture)

--[=[
	@class Vector3ArgumentType
]=]
local Vector3ArgumentType = {}
Vector3ArgumentType.__index = Vector3ArgumentType

local COORDINATE_TYPES = {
	ABSOLUTE = "absolute" :: "absolute",
	LOCAL = "local" :: "local",
	RELATIVE = "relative" :: "relative",
}

export type Vector3ArgumentType = ArgumentType.ArgumentType<ParsedVector3Result>

type ArgumentType<T> = ArgumentType.ArgumentType<T>
type CommandContext<S> = CommandContext.CommandContext<S>
type CompletableFuture<T> = CompletableFuture.CompletableFuture<T>
type Suggestions = Suggestions.Suggestions
type SuggestionsBuilder = SuggestionsBuilder.SuggestionsBuilder

export type ParsedVector3Result = {
	x: CoordinateData,
	y: CoordinateData,
	z: CoordinateData
}

export type CoordinateData = {
	type: "relative" | "absolute" | "local",
	value: number
}

function Vector3ArgumentType.vec3(): Vector3ArgumentType
	return setmetatable({}, Vector3ArgumentType) :: Vector3ArgumentType
end

function Vector3ArgumentType.resolveAndGetVec3<S>(context: CommandContext.CommandContext<S>, name: string, source: any): Vector3
	return Vector3ArgumentType.resolveVec3(Vector3ArgumentType.getVec3(context, name), source)
end

function Vector3ArgumentType.getVec3<S>(context: CommandContext.CommandContext<S>, name: string): ParsedVector3Result
	local vec3Arg = context:getArgument(name)
	if type(vec3Arg) ~= "table" then
		error(`Argument '{name}' results in a value of type {typeof(vec3Arg)}, expected table`)
	end
	return vec3Arg
end

function Vector3ArgumentType.resolveVec3(parsedVec3Result: ParsedVector3Result, source: any): Vector3
	local sourcePos = Vector3.new(0, 0, 0)
	local sourceLook = Vector3.new(0, 0, -1) -- Forward direction
	local sourceRight = Vector3.new(1, 0, 0) -- Right direction
	local sourceUp = Vector3.new(0, 1, 0)    -- Up direction
	
	-- Get source position and orientation if it's a player
	if typeof(source) == "Instance" and source:IsA("Player") and source.Character then
		local character = source.Character :: Model
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
			sourcePos = humanoidRootPart.Position
			sourceLook = humanoidRootPart.CFrame.LookVector
			sourceRight = humanoidRootPart.CFrame.RightVector  
			sourceUp = humanoidRootPart.CFrame.UpVector
		end
	end
	
	return Vector3.new(
		Vector3ArgumentType.resolveCoord(parsedVec3Result.x, sourcePos.X, sourceRight),
		Vector3ArgumentType.resolveCoord(parsedVec3Result.y, sourcePos.Y, sourceUp), 
		Vector3ArgumentType.resolveCoord(parsedVec3Result.z, sourcePos.Z, sourceLook)
	)
end

function Vector3ArgumentType.resolveCoord(coord: CoordinateData, currentPos: number, localAxis: Vector3): number
	if coord.type == COORDINATE_TYPES.ABSOLUTE then
		return coord.value
	elseif coord.type == COORDINATE_TYPES.RELATIVE then
		return currentPos + coord.value
	elseif coord.type == COORDINATE_TYPES.LOCAL then
		-- Local coordinates are relative to entity's facing direction
		return currentPos + coord.value
	end
	return coord.value
end

--

function Vector3ArgumentType.parse(self: Vector3ArgumentType, input: string): (ParsedVector3Result, number)
	local remaining = input
	local coords: { CoordinateData } = {}
	local totalConsumed = 0
	
	for i = 1, 3 do
		local whitespace = remaining:match("^(%s*)") :: string
		local wsLength = #whitespace
		remaining = remaining:sub(wsLength + 1)
		totalConsumed = totalConsumed + wsLength

		local coord, consumed = Vector3ArgumentType.parseCoordinate(remaining)
		if not coord then
			error(`Expected coordinate {i == 1 and "x" or i == 2 and "y" or "z"}`)
		end
		
		coords[i] = coord
		
		remaining = remaining:sub(consumed + 1)
		totalConsumed = totalConsumed + consumed
	end
	
	return {
		x = coords[1],
		y = coords[2],
		z = coords[3]
	}, totalConsumed
end

function Vector3ArgumentType.parseCoordinate(input: string): (CoordinateData?, number)
	-- Relative coordinate: ~5, ~-10, ~, ~1.5, ~.25
	local relativeMatch = input:match("^~(%-?%d*%.?%d*)")
	if relativeMatch ~= nil then
		-- Handle empty string after ~ (just "~")
		local offset = (relativeMatch == "" and 0) or tonumber(relativeMatch)
		local consumed = 1 + #relativeMatch
		return {
			type = COORDINATE_TYPES.RELATIVE,
			value = offset :: number
		}, consumed
	end
	
	-- Local coordinate: ^5, ^-2, ^, ^1.5, ^.25
	local localMatch = input:match("^%^(%-?%d*%.?%d*)")
	if localMatch ~= nil then
		local offset = (localMatch == "" and 0) or tonumber(localMatch)
		local consumed = 1 + #localMatch
		return {
			type = COORDINATE_TYPES.LOCAL, 
			value = offset :: number
		}, consumed
	end
	
	-- Absolute coordinate: 10, -5, 0, 1.25, -0.75
	local absoluteMatch = input:match("^(%-?%d+%.?%d*)")
	if absoluteMatch then
		return {
			type = COORDINATE_TYPES.ABSOLUTE,
			value = tonumber(absoluteMatch) :: number
		}, #absoluteMatch
	end
	
	return nil, 0
end

function Vector3ArgumentType.listSuggestions<S>(self: Vector3ArgumentType, context: CommandContext<S>, builder: SuggestionsBuilder): CompletableFuture<Suggestions>
	local remaining = builder:getRemaining()
	
	-- Split what the user typed by spaces
	-- e.g. if they typed "~ 10", parts will be {"~", "10"}
	local parts = string.split(remaining, " ")
	local count = #parts

	-- Only suggest what's missing
	if count <= 1 then
		-- User is on the first number (X)
		builder:suggest("~")
		builder:suggest("~ ~")
		builder:suggest("~ ~ ~")
	elseif count == 2 then
		-- Aalready typed X, suggest Y
		local x = parts[1]
		builder:suggest(x .. " ~")
		builder:suggest(x .. " ~ ~")
	elseif count == 3 then
		-- Already typed X and Y, suggest Z
		local x = parts[1]
		local y = parts[2]
		builder:suggest(x .. " " .. y .. " ~")
	end

	return builder:buildFuture()
end

return Vector3ArgumentType