--!strict

local camera = workspace.CurrentCamera

local WorldPointer = {}
WorldPointer.__index = WorldPointer

export type WorldPointer = typeof(setmetatable({} :: {
	read guiFrame: Frame,
	read originalAbsolutePos: Vector2,
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
	if self.targetPos then
		self:rotateFrameByAnchor()
	end
end

function WorldPointer.setTargetPos(self: WorldPointer, pos: Vector3?): ()
	self.targetPos = pos
end

function WorldPointer.rotateFrameByAnchor(self: WorldPointer): ()
	local frame = self.guiFrame

	-- rotiation calculations
	local centerCframe = calculateCenterCframe(camera)
	local angle = calculateAngle(centerCframe, self.targetPos :: Vector3)
	local theta = math.rad(angle)

	-- rotate by anchor
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

	frame.Position = UDim2.new(0, nonRotatedAnchor.X + difference.X + offset.X, 0, nonRotatedAnchor.Y + difference.Y + offset.Y)
	frame.Rotation = math.deg(theta)
end

return WorldPointer