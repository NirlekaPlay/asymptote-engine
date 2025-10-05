--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

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

function Vector3ArgumentType.resolveAndGetVec3<S>(context: CommandContext.CommandContext<S>, name: string, source: S): Vector3
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
	
	-- Parse 3 coordinates (x, y, z)
	for i = 1, 3 do
		-- Skip whitespace
		remaining = remaining:match("^%s*(.*)") or remaining
		
		-- Try to parse a coordinate (can be relative ~, absolute number, or local ^)
		local coord, consumed = Vector3ArgumentType.parseCoordinate(remaining)
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

return Vector3ArgumentType