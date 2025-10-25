--!strict

--[=[
	@class ZoneUtil

	From [InfiltrationEngine's](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions)
	[ZoneUtil](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions/blob/main/Plugins/src/SerializationTools/Util/ZoneUtil.lua)
	module.
]=]
local ZoneUtil = {}

--[=[
	Returns `true` if the position `pos` is inside the given `zoneModel`.

	A position is considered inside a zone if:
	 * It lies within the horizontal (X-Z) footprint of at least one Floor and one Roof part in the zone.
	 * Vertically, it is above the Floor center and below the Roof center.

	Only BasePart children named "Floor" or "Roof" are considered.
]=]
function ZoneUtil.isPosInZone(pos: Vector3, zoneModel: Model): boolean
	local floorMatch = zoneModel:FindFirstChild("Floor") == nil
	local roofMatch = false

	for _, part in pairs(zoneModel:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		local rel = part.CFrame:PointToObjectSpace(pos)

		if math.abs(rel.X) <= part.Size.X / 2 and math.abs(rel.Z) <= part.Size.Z / 2 then
			if part.Name == "Roof" and rel.Y <= 0 then
				roofMatch = true
			elseif part.Name == "Floor" and rel.Y >= 0 then
				floorMatch = true
			end

			if floorMatch and roofMatch then
				return true
			end
		end
	end
	
	return false
end

function ZoneUtil.getPosOccupiedZoneModel(zonesFolder: Instance, pos: Vector3): Model?
	for _, zone in pairs(zonesFolder:GetChildren()) do
		if zone:IsA("Model") and ZoneUtil.isPosInZone(zone, pos) then
			return zone
		end
	end
	return nil
end

return ZoneUtil