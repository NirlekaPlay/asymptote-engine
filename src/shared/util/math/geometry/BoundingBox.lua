--!strict

local BoundingBox = {}

export type ViewportCorner = {
	screenPos: Vector3,
	onScreen: boolean
}

function BoundingBox.getCornersFromBoundingBox(cframe: CFrame, size: Vector3): {Vector3}
	local halfSize = size / 2
	local corners: {Vector3} = {}
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local offset = Vector3.new(x * halfSize.X, y * halfSize.Y, z * halfSize.Z)
				table.insert(corners, cframe:PointToWorldSpace(offset))
			end
		end
	end
	return corners
end

function BoundingBox.getViewportCorners(corners: {Vector3}, camera: Camera): {ViewportCorner}
	local viewportCorners: {ViewportCorner} = {}
	for _, corner in ipairs(corners) do
		local screenPos, onScreen = camera:WorldToViewportPoint(corner)
		table.insert(viewportCorners, {screenPos = screenPos, onScreen = onScreen})
	end
	return viewportCorners
end

function BoundingBox.isBoundingBoxInViewByViewportCorners(viewportCorners: {ViewportCorner}): boolean
	for _, corner in ipairs(viewportCorners) do
		if corner.onScreen and corner.screenPos.Z > 0 then
			return true
		end
	end
	return false
end

return BoundingBox