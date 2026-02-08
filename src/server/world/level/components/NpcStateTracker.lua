--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local function isEmptyString(str: string?): boolean
	if not str then
		return true
	end

	return string.match(str, "%S") == nil
end

--[=[
	@class NpcStateTracker

	Tracks the states of tagged NPC(s) and sets a variable if that state changes.
]=]
local NpcStateTracker = {}
NpcStateTracker.__index = NpcStateTracker

export type NpcStateTracker = StateComponent.StateComponent & typeof(setmetatable({} :: {
	npcServerTag: string,
	deathCountVariable: string?,
	maid: Maid.Maid
}, NpcStateTracker))

function NpcStateTracker.fromInstance(inst: Instance): NpcStateTracker
	local npcServerTag = inst:GetAttribute("NpcServerTag") :: string
	if isEmptyString(npcServerTag) then
		error(`Empty 'NpcServerTag': NpcStateTracker currently cannot track all NPCs.`)
	end
	local deathCountVariable = inst:GetAttribute("DeathCountVariable") :: string
	if not isEmptyString(deathCountVariable) then
		if not GlobalStatesHolder.hasState(deathCountVariable) then
			GlobalStatesHolder.setState(deathCountVariable, 0)
		end
	end

	local maid = Maid.new()

	-- TODO: Bad practice. Will fix later.
	local function proccessTagged(tagged: Instance)
		if tagged:IsA("Model") and tagged.Parent == workspace and tagged:FindFirstChildOfClass("Humanoid") then
			local conns: {RBXScriptConnection} = {}
			if not isEmptyString(deathCountVariable) then
				local humanoid = tagged:FindFirstChildOfClass("Humanoid") :: Humanoid
				local diedConn = maid:giveTask(humanoid.Died:Once(function()
					GlobalStatesHolder.setState(deathCountVariable, GlobalStatesHolder.getState(deathCountVariable) + 1)
				end))

				table.insert(conns, diedConn)
			end

			maid:giveTask(tagged.Destroying:Once(function()
				for _, conn in conns do
					conn:Disconnect()
				end
			end))
		end
	end

	for _, tagged in CollectionService:GetTagged(npcServerTag) do
		proccessTagged(tagged)
	end

	maid:giveTask(CollectionService:GetInstanceAddedSignal(npcServerTag):Connect(function(tagged)
		proccessTagged(tagged)
	end))

	return setmetatable({
		npcServerTag = npcServerTag,
		deathCountVariable = deathCountVariable :: string?,
		maid = maid
	}, NpcStateTracker) :: NpcStateTracker
end

function NpcStateTracker.onLevelRestart(self: NpcStateTracker): ()
	if self.deathCountVariable then
		GlobalStatesHolder.setState(self.deathCountVariable, 0)
	end
end

--

function NpcStateTracker.destroy(self: NpcStateTracker, serverLevel: ServerLevel.ServerLevel): ()
	self.maid:doCleaning()
end

return NpcStateTracker