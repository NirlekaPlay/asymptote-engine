--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Entity = require(ServerScriptService.server.world.entity.Entity)

local math_floor = math.floor
local table_clear = table.clear

local SECTION_SIZE = 16 -- NOTE: In Minecraft, this is 16 blocks. But Roblox studs are different, 1 block in Minecraft is equal to about 4 studs
local HASH_X = 73856093 -- ref: https://stackoverflow.com/questions/5928725/hashing-2d-3d-and-nd-vectors
local HASH_Y = 19349663 -- I don't know what wizardry these prime numbers do but it's important for the hashing
local HASH_Z = 83492791

local function getSectionKey(pos: Vector3): number
	local sx = math_floor(pos.X / SECTION_SIZE)
	local sy = math_floor(pos.Y / SECTION_SIZE)
	local sz = math_floor(pos.Z / SECTION_SIZE)

	return (sx * HASH_X) + (sy * HASH_Y) + (sz * HASH_Z)
end

--[=[
	@class EntitySectionManager
]=]
local EntitySectionManager = {}
EntitySectionManager.__index = EntitySectionManager

export type EntitySectionManager = typeof(setmetatable({} :: {
	sections: Map<SectionKey, Set<Entity>>,
	entityToSection: Map<Entity, SectionKey>
}, EntitySectionManager))

type Entity = Entity.Entity
type Map<K, V> = { [K]: V }
type Set<T> = { [T]: true }
type SectionKey = number

function EntitySectionManager.new(): EntitySectionManager
	return setmetatable({
		sections = {},
		entityToSection = {}
	}, EntitySectionManager)
end

--

function EntitySectionManager.getEntitiesInRange(self: EntitySectionManager, origin: Vector3, minDist: number, maxDist: number): {Entity}
	local foundEntities: {Entity} = {}
	local count = 0

	local ox, oy, oz = origin.X, origin.Y, origin.Z
	
	local minSx = math_floor((ox - maxDist) / SECTION_SIZE)
	local maxSx = math_floor((ox + maxDist) / SECTION_SIZE)
	local minSy = math_floor((oy - maxDist) / SECTION_SIZE)
	local maxSy = math_floor((oy + maxDist) / SECTION_SIZE)
	local minSz = math_floor((oz - maxDist) / SECTION_SIZE)
	local maxSz = math_floor((oz + maxDist) / SECTION_SIZE)

	local minSq, maxSq = minDist * minDist, maxDist * maxDist
	local sections = self.sections

	for sx = minSx, maxSx do
		local hX = sx * HASH_X
		for sy = minSy, maxSy do
			local hXY = hX + (sy * HASH_Y)
			for sz = minSz, maxSz do
				local key = hXY + (sz * HASH_Z)
				local section = sections[key]
				
				if section then
					for entity in section do
						local ep = entity:getPosition()
						local dx, dy, dz = ep.X - ox, ep.Y - oy, ep.Z - oz
						local dSq = dx*dx + dy*dy + dz*dz
						
						if dSq >= minSq and dSq <= maxSq then
							count += 1
							foundEntities[count] = entity
						end
					end
				end
			end
		end
	end

	return foundEntities
end

--

function EntitySectionManager.update(self: EntitySectionManager): ()
	for entity in self.entityToSection do
		self:updateEntityPosition(entity)
	end
end

function EntitySectionManager.addEntity(self: EntitySectionManager, entity: Entity): ()
	local key = getSectionKey(entity:getPosition())
	
	if not self.sections[key] then
		self.sections[key] = {}
	end

	self.sections[key][entity] = true
	self.entityToSection[entity] = key
end

function EntitySectionManager.removeEntity(self: EntitySectionManager, entity: Entity): ()
	local key = self.entityToSection[entity]
	
	if key then
		local section = self.sections[key]
		if section then
			section[entity] = nil
			-- Should we clean up the table if its empty?
			-- Hmmm... I dunno. Might lead to some table creation and deletion bullshit
			-- Guess we're gonna see after the benchmark.

			--[=[
			if not next(section) then
				self.sections[key] = nil
			end
			]=]
		end

		self.entityToSection[entity] = nil
	end
end

function EntitySectionManager.clearEntities(self: EntitySectionManager): ()
	table_clear(self.sections)
	table_clear(self.entityToSection)
end

function EntitySectionManager.updateEntityPosition(self: EntitySectionManager, entity: Entity)
	local oldKey = self.entityToSection[entity]
	local newKey = getSectionKey(entity:getPosition())

	if oldKey ~= newKey then
		self.sections[oldKey][entity] = nil

		if not self.sections[newKey] then
			self.sections[newKey] = {}
		end
		self.sections[newKey][entity] = true
		self.entityToSection[entity] = newKey
	end
end

return EntitySectionManager