--!nonstrict

local Players = game:GetService("Players")

--[=[
	@class TriggerZone

	Gives a list of players where its HumanoidRootPart is
	completly inside a zone, defined with Region3.
]=]
local TriggerZone = {}
TriggerZone.__index = TriggerZone

export type TriggerZone = typeof(setmetatable({} :: {
	region: Region3,
	playersInZone: { [Player]: true },
	lastPlayersInZone: { [Player]: true },
	onPlayerEnterCallback: Callback?,
	onPlayerLeaveCallback: Callback?
}, TriggerZone))

type Callback = ( Player ) -> ()

function TriggerZone.new(min: Vector3, max: Vector3, onEnter: Callback?, onLeave: Callback?): TriggerZone
	return setmetatable({
		region = Region3.new(min, max),
		playersInZone = {},
		lastPlayersInZone = {},
		onPlayerEnterCallback = onEnter,
		onPlayerLeaveCallback = onLeave
	}, TriggerZone)
end

function TriggerZone.fromPart(part: BasePart, onEnter: Callback?, onLeave: Callback?): TriggerZone
	-- oh god what is this?

	local abs = math.abs

	local cf = part.CFrame -- this causes a LuaBridge invocation + heap allocation to create CFrame object - expensive! - but no way around it. we need the cframe
	local size = part.Size -- this causes a LuaBridge invocation + heap allocation to create Vector3 object - expensive! - but no way around it
	local sx, sy, sz = size.X, size.Y, size.Z -- this causes 3 Lua->C++ invocations

	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents() -- this causes 1 Lua->C++ invocations and gets all components of cframe in one go, with no allocations

	-- https://zeux.io/2010/10/17/aabb-from-obb-with-component-wise-abs/
	local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz) -- this requires 3 Lua->C++ invocations to call abs, but no hash lookups since we cached abs value above; otherwise this is just a bunch of local ops
	local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz) -- same
	local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz) -- same
	
	-- just a bunch of local ops
	local minx = x - wsx
	local miny = y - wsy
	local minz = z - wsz

	local maxx = x + wsx
	local maxy = y + wsy
	local maxz = z + wsz

	local minv, maxv = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)

	return TriggerZone.new(minv, maxv, onEnter, onLeave)
end

function TriggerZone.update(self: TriggerZone): ()
	self.lastPlayersInZone = self.playersInZone
	local players = Players:GetPlayers()
	local playersInZone: { [Player]: true } = {}

	for _, player in ipairs(players) do
		local character = player.Character
		if not character then
			continue
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			continue
		end

		if not self:isPartWithinZone(humanoidRootPart) then
			continue
		end

		playersInZone[player] = true
		if not self.lastPlayersInZone[player] then
			self.onPlayerEnterCallback(player)
		end
	end

	for player in pairs(self.lastPlayersInZone) do
		if not playersInZone[player] then
			self.onPlayerLeaveCallback(player)
		end
	end

	self.playersInZone = playersInZone
end

function TriggerZone.isPointWithinZone(self: TriggerZone, point: Vector3): boolean
	local region = self.region
	local v3 = region.CFrame:PointToObjectSpace(point)
	return (math.abs(v3.X) <= region.Size.X / 2)
		and (math.abs(v3.Y) <= region.Size.Y / 2)
		and (math.abs(v3.Z) <= region.Size.Z / 2)
end

function TriggerZone.isPartWithinZone(self: TriggerZone, part: BasePart): boolean
	local size = part.Size / 2
	local corners = {
		part.CFrame * CFrame.new(size.X, size.Y, size.Z),
		part.CFrame * CFrame.new(size.X, size.Y, -size.Z),
		part.CFrame * CFrame.new(size.X, -size.Y, size.Z),
		part.CFrame * CFrame.new(size.X, -size.Y, -size.Z),
		part.CFrame * CFrame.new(-size.X, size.Y, size.Z),
		part.CFrame * CFrame.new(-size.X, size.Y, -size.Z),
		part.CFrame * CFrame.new(-size.X, -size.Y, size.Z),
		part.CFrame * CFrame.new(-size.X, -size.Y, -size.Z)
	}

	for _, cframe in ipairs(corners) do
		-- if any corner is outside, stop
		if (not self:isPointWithinZone(cframe.Position)) then
			return false
		end
	end

	return true
end

return TriggerZone