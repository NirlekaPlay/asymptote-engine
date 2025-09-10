--!strict

local camera = workspace.CurrentCamera


--[=[
	@class WorldPointer

	Makes Frames rotate on its anchor towards a position
	in world space.
]=]
local WorldPointer = {}
WorldPointer.__index = WorldPointer

export type WorldPointer = typeof(setmetatable({} :: {
	guiFrame: Frame,
	originalAbsolutePos: Vector2,
	targetPos: Vector3?
}, WorldPointer))

local function calculateCenterCframe(camera: Camera)
	local position = camera.CFrame.Position
	local look_direction = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	return CFrame.new(position, position + look_direction)
end

local function calculateAngle(center: CFrame, point: Vector3)
	local relative_point = center:PointToObjectSpace(point)
	local angle_radians = math.atan2(relative_point.Z, relative_point.X)
	return math.deg(angle_radians) + 90
end

function WorldPointer.new(frame: Frame, targetPos: Vector3?): WorldPointer
	return setmetatable({
		guiFrame = frame,
		originalAbsolutePos = frame.AbsolutePosition,
		targetPos = targetPos :: Vector3?
	}, WorldPointer)
end

function WorldPointer.update(self: WorldPointer): ()
	if not self.targetPos then
		return
	end

	-- Fucking piece of shit of a typechecker
	-- why is it of `any` type you bastard
	local frame = self.guiFrame :: Frame
	local frameRot = self:getFrameRotTowardsTargetWorldPos()

	--frame.Position = frame.Position:Lerp(framePos, 0.5)
	frame.Rotation = math.lerp(frame.Rotation, frameRot, 0.5)
end

function WorldPointer.setTargetPos(self: WorldPointer, pos: Vector3?): ()
	self.targetPos = pos
end

function WorldPointer.getFrameRotTowardsTargetWorldPos(self: WorldPointer): number
	-- rotiation calculations
	local centerCframe = calculateCenterCframe(camera)
	local angle = calculateAngle(centerCframe, self.targetPos :: Vector3)
	local theta = math.deg(math.rad(angle))

	--[[
	-- rotate by anchor
	-- for the old anchor based rotation, remove math.deg from theta
	local frame = self.guiFrame
	local size = frame.AbsoluteSize;
	local topLeftCorner = self.originalAbsolutePos - size * frame.AnchorPoint
	
	local offset = size * frame.AnchorPoint
	local center = topLeftCorner + size / 2
	local nonRotatedAnchor = topLeftCorner + offset
	
	local cos, sin = math.cos(theta), math.sin(theta)
	local v = nonRotatedAnchor - center
	local rv = Vector2.new(v.X * cos - v.Y * sin, v.X * sin + v.Y * cos)
	
	local rotatedAnchor = center + rv
	local difference = nonRotatedAnchor - rotatedAnchor

	local framePos = UDim2.new(0, nonRotatedAnchor.X + difference.X + offset.X, 0, nonRotatedAnchor.Y + difference.Y + offset.Y)
	local frameRot =  math.deg(theta)]]

	return theta
end

return WorldPointer