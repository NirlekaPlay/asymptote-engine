--!strict

--[=[
	@class PersistentInstanceManager
]=]
local PersistentInstanceManager = {}
PersistentInstanceManager.__index = PersistentInstanceManager

export type PersistentInstanceManager = typeof(setmetatable({} :: {
	instanceStorageSet: { [Instance]: true },
	instancesDestroyedConns: { [Instance]: RBXScriptConnection },
	scheduledInstancesForDestroy: { [Instance]: number }
}, PersistentInstanceManager))

function PersistentInstanceManager.new(): PersistentInstanceManager
	return setmetatable({
		instanceStorageSet = {},
		instancesDestroyedConns = {},
		scheduledInstancesForDestroy = {}
	}, PersistentInstanceManager)
end

function PersistentInstanceManager.register(self: PersistentInstanceManager, inst: Instance): ()
	if not self.instanceStorageSet[inst] then
		self.instanceStorageSet[inst] = true
		self.instancesDestroyedConns[inst] = inst.Destroying:Once(function()
			self:destroyInstance(inst)
		end)
	end
end

function PersistentInstanceManager.registerInstances(self: PersistentInstanceManager, insts: {Instance}): ()
	for _, inst in insts do
		self:register(inst)
	end
end

function PersistentInstanceManager.destroyAll(self: PersistentInstanceManager): ()
	local instancesToDestroy: { [Instance]: true } = {} -- Is this even necessary?

	for instance in self.instanceStorageSet do
		instancesToDestroy[instance] = true
	end

	for instance in instancesToDestroy do
		self:destroyInstance(instance)
	end
end

function PersistentInstanceManager.destroyInstance(self: PersistentInstanceManager, inst: Instance): ()
	if self.instanceStorageSet[inst] then
		self.instanceStorageSet[inst] = nil
	end

	if self.instancesDestroyedConns[inst] then
		self.instancesDestroyedConns[inst]:Disconnect()
		self.instancesDestroyedConns[inst] = nil
	end

	if self.scheduledInstancesForDestroy[inst] then
		self.scheduledInstancesForDestroy[inst] = nil
	end

	inst:Destroy()
end

function PersistentInstanceManager.scheduleDestroy(
	self: PersistentInstanceManager, inst: Instance, timeInSec: number
): ()
	self:register(inst)

	self.scheduledInstancesForDestroy[inst] = timeInSec
end

function PersistentInstanceManager.update(self: PersistentInstanceManager, deltaTime: number): ()
	self:destroyExpiredInstances(deltaTime)
end

function PersistentInstanceManager.destroyExpiredInstances(
	self: PersistentInstanceManager, deltaTime: number
): ()
	if next(self.scheduledInstancesForDestroy) == nil then
		return
	end
	
	local instancesToBeRemoved: { [Instance]: true } = {}

	for instance in self.scheduledInstancesForDestroy do
		self.scheduledInstancesForDestroy[instance] -= deltaTime
		local ttl = self.scheduledInstancesForDestroy[instance]

		if ttl <= 0 then
			instancesToBeRemoved[instance] = true
		end
	end

	for instance in instancesToBeRemoved do
		self:destroyInstance(instance)
	end
end

return PersistentInstanceManager