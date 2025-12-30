--!strict

local lib = {}

function lib.isPosInBounds(pos: Vector3, cframe: CFrame, size: Vector3): boolean
	local v3 = cframe:PointToObjectSpace(pos)
	return (math.abs(v3.X) <= size.X / 2)
		and (math.abs(v3.Y) <= size.Y / 2)
		and (math.abs(v3.Z) <= size.Z / 2)
end

function lib.isPosInPart(pos: Vector3, part: BasePart): boolean
	return lib.isPosInBounds(pos, part.CFrame, part.Size)
end

return lib