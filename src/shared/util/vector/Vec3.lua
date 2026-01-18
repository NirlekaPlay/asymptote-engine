--!strict

local abs = math.abs

local Vec3 = {}

function Vec3.distManhattan(vec1: Vector3, vec2: Vector3): number
	local dx = abs(vec1.X - vec2.X)
	local dy = abs(vec1.Y - vec2.Y)
	local dz = abs(vec1.Z - vec2.Z)

	return dx + dy + dz
end

return Vec3