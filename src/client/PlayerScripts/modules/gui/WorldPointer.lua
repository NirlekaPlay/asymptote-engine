--!strict

local camera = workspace.CurrentCamera

local pointer = {}

export type WorldPointer = {
	read gui_frame: Frame,
	read og_abs_pos: Vector2,
	target_pos: Vector3
}

local function rotate_frame_by_anchor(frame: Frame, frame_og_abs_pos: Vector2, theta: number): ()
	local size = frame.AbsoluteSize;
	local topLeftCorner = frame_og_abs_pos - size * frame.AnchorPoint

	local offset = size * frame.AnchorPoint;
	local center = topLeftCorner + size / 2
	local nonRotatedAnchor = topLeftCorner + offset;

	local cos, sin = math.cos(theta), math.sin(theta);
	local v = nonRotatedAnchor - center;
	local rv = Vector2.new(v.X * cos - v.Y * sin, v.X  * sin + v.Y * cos);

	local rotatedAnchor = center + rv;
	local difference = nonRotatedAnchor - rotatedAnchor;

	frame.Position = UDim2.new(0, nonRotatedAnchor.X + difference.X + offset.X, 0, nonRotatedAnchor.Y + difference.Y + offset.Y);
	frame.Rotation = math.deg(theta);
end

local function calculate_center_cframe(camera: Camera)
	local position = camera.CFrame.Position
	local look_direction = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	return CFrame.new(position, position + look_direction)
end

local function calculate_angle(center: CFrame, point: Vector3)
	local relative_point = center:PointToObjectSpace(point)
	local angle_radians = math.atan2(relative_point.Z, relative_point.X)
	return math.deg(angle_radians) + 90
end

local function rotate_frame_to_world_pos(world_pos: Vector3, frame: Frame, frame_og_abs_pos: Vector2)
	local centerCFrame = calculate_center_cframe(camera)
	local angle = calculate_angle(centerCFrame, world_pos)

	rotate_frame_by_anchor(frame, frame_og_abs_pos, math.rad(angle))
end


function pointer.create(frame: Frame, target_pos: Vector3): WorldPointer
	return {
		gui_frame = frame,
		og_abs_pos = frame.AbsolutePosition,
		target_pos = target_pos
	} :: WorldPointer
end

function pointer.update(self: WorldPointer)
	rotate_frame_to_world_pos(self.target_pos, self.gui_frame, self.og_abs_pos)
end

return pointer