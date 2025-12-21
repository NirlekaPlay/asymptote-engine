--!strict

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
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

export type NpcStateTracker = typeof(setmetatable({} :: {
	npcServerTag: string,
	deathCountVariable: string?
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

	-- TODO: Bad practice. Will fix later.
	local function proccessTagged(tagged: Instance)
		if tagged:IsA("Model") and tagged.Parent == workspace and tagged:FindFirstChildOfClass("Humanoid") then
			local conns: {RBXScriptConnection} = {}
			if not isEmptyString(deathCountVariable) then
				local humanoid = tagged:FindFirstChildOfClass("Humanoid") :: Humanoid
				local diedConn = humanoid.Died:Once(function()
					GlobalStatesHolder.setState(deathCountVariable, GlobalStatesHolder.getState(deathCountVariable) + 1)
				end)

				table.insert(conns, diedConn)
			end

			tagged.Destroying:Once(function()
				for _, conn in conns do
					conn:Disconnect()
				end
			end)
		end
	end

	for _, tagged in CollectionService:GetTagged(npcServerTag) do
		proccessTagged(tagged)
	end

	-- TODO: Disconnect this later.
	-- But should we?
	-- Since state components wont get destroyed anyway
	-- best to leave it...
	CollectionService:GetInstanceAddedSignal(npcServerTag):Connect(function(tagged)
		proccessTagged(tagged)
	end)

	return setmetatable({
		npcServerTag = npcServerTag,
		deathCountVariable = deathCountVariable :: string?
	}, NpcStateTracker)
end

function NpcStateTracker.onLevelRestart(self: NpcStateTracker): ()
	if self.deathCountVariable then
		GlobalStatesHolder.setState(self.deathCountVariable, 0)
	end
end

return NpcStateTracker