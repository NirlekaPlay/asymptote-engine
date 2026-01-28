--!strict

local currentCamera = workspace.CurrentCamera
local CONST_ROT_ALPHA = 0.5

--[=[
	@class WorldPointer

	Makes a Frame rotate towards a position in world space.
]=]
local WorldPointer = {}
WorldPointer.__index = WorldPointer

export type WorldPointer = typeof(setmetatable({} :: {
	frame: Frame,
	targetPos: Vector3?
}, WorldPointer))

local function calculateRotationTowardsWorldPos(worldPos: Vector3): number
	local cameraCframe = currentCamera.CFrame
	local worldDirection = worldPos - cameraCframe.Position
	local relativeDirection = cameraCframe:VectorToObjectSpace(worldDirection)
	local relativeDirection2D = Vector2.new(relativeDirection.X, relativeDirection.Y).Unit

	local angle = math.atan2(relativeDirection2D.X, relativeDirection2D.Y)

	return math.deg(angle)
end

local function lerpAngle(current: number, target: number, alpha: number): number
	-- this solves a classic problem with interpolating angles
	-- this prevents angles getting lerped in the other direction
	-- instead of lerping to the closest rotation.
	local delta = (target - current + 180) % 360 - 180
	return current + delta * alpha
end

function WorldPointer.new(frame: Frame, targetPos: Vector3?): WorldPointer
	return setmetatable({
		frame = frame,
		targetPos = targetPos :: Vector3?
	}, WorldPointer)
end

function WorldPointer.setTargetPos(self: WorldPointer, pos: Vector3?): ()
	self.targetPos = pos
end

function WorldPointer.update(self: WorldPointer): ()
	if not self.targetPos then
		return
	end

	-- Fucking piece of shit of a typechecker
	-- why is it of `any` type you bastard
	local frame = self.frame :: Frame
	local frameRot = calculateRotationTowardsWorldPos(self.targetPos)

	frame.Rotation = lerpAngle(frame.Rotation, frameRot, CONST_ROT_ALPHA)
end

return WorldPointer