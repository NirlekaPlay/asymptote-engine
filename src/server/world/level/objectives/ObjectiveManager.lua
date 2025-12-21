--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local ParsedObjective = require(ServerScriptService.server.world.level.objectives.ParsedObjective)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)

--[=[
	@class ObjectiveManager
]=]
local ObjectiveManager = {}
ObjectiveManager.__index = ObjectiveManager

export type ObjectiveManager = typeof(setmetatable({} :: {
	-- Key: Header name (e.g., "Mission", "Stealth")
	-- Value: Table of ParsedObjectiveEntry structures
	parsedObjectives: { [string]: { [number]: ParsedObjectiveEntry } },
	currentActiveObjectives: { [string]: {text: string, tag: string} }
}, ObjectiveManager))

export type RawObjectiveEntry = {
	Active: string,
	Text: string?,
	Tag: string?,
	Header: string?,
	SubState: { [number]: RawObjectiveEntry }?,
}

export type RawMissionSetupTable = { [string]: { [number]: RawObjectiveEntry } }

export type ParsedObjectiveEntry = ParsedObjective.ParsedObjective | {
	parsedObjective: ParsedObjective.ParsedObjective,
	SubState: { [number]: ParsedObjectiveEntry },
}

function ObjectiveManager.new(): ObjectiveManager
	return setmetatable({
		parsedObjectives = {},
		currentActiveObjectives = {}
	}, ObjectiveManager)
end

function ObjectiveManager.fromMissionSetupTable(self: ObjectiveManager, missionTable: RawMissionSetupTable)
	for headerName, objectiveList in pairs(missionTable) do
		-- Skip the Timer table or other non-objective tables if present
		if typeof(objectiveList) == "table" and headerName ~= "Timer" then
			local parsedList: { [number]: ParsedObjectiveEntry } = {}
			for i, rawEntry in ipairs(objectiveList) do
				parsedList[i] = ObjectiveManager.parseObjectiveEntry(rawEntry)
			end
			self.parsedObjectives[headerName] = parsedList
		end
	end
end

function ObjectiveManager.parseObjectiveEntry(rawEntry: RawObjectiveEntry): ParsedObjectiveEntry
	if rawEntry.SubState then
		local subStateTable: { [number]: ParsedObjectiveEntry } = {}
		for i, subEntry in ipairs(rawEntry.SubState) do
			subStateTable[i] = ObjectiveManager.parseObjectiveEntry(subEntry)
		end
		-- Wrap SubState container in a ParsedObjective for consistent evaluation
		return {
			parsedObjective = ParsedObjective.new(
				rawEntry.Active,
				rawEntry.Tag or "",
				rawEntry.Text or ""
			),
			SubState = subStateTable
		}
	else
		return ParsedObjective.new(
			rawEntry.Active,
			rawEntry.Tag or "",
			rawEntry.Text or ""
		)
	end
end

function ObjectiveManager.objectivesHaveChanged(
	self: ObjectiveManager, 
	newObjectives: { [string]: {text: string, tag: string} }
): boolean
	-- Check if any header was added or removed
	for headerName in pairs(newObjectives) do
		if not self.currentActiveObjectives[headerName] then
			return true -- New header appeared
		end
	end
	
	for headerName in pairs(self.currentActiveObjectives) do
		if not newObjectives[headerName] then
			return true -- Header disappeared
		end
	end
	
	-- Check if text or tag changed for existing headers
	for headerName, newData in pairs(newObjectives) do
		local currentData = self.currentActiveObjectives[headerName]
		if currentData.text ~= newData.text or currentData.tag ~= newData.tag then
			return true -- Content changed
		end
	end
	
	return false
end

function ObjectiveManager.update(self: ObjectiveManager, context: ExpressionContext.ExpressionContext): ()
	-- TODO: Listen for variable changes instead of frame updates.

	local displayData = self:getDisplayedObjectives(context)
	
	if self:objectivesHaveChanged(displayData) then
		self.currentActiveObjectives = displayData
		self:sendCurrentObjectivesToClients()
	end
end

function ObjectiveManager.sendCurrentObjectivesToClients(self: ObjectiveManager): ()
	TypedRemotes.ClientBoundObjectivesInfo:FireAllClients(self.currentActiveObjectives)
end

function ObjectiveManager.sendCurrentObjectivesToPlayer(self: ObjectiveManager, player: Player): ()
	TypedRemotes.ClientBoundObjectivesInfo:FireClient(player, self.currentActiveObjectives)
end

function ObjectiveManager.getActiveObjectiveByFirstValid(self: ObjectiveManager, objectiveList: { [number]: ParsedObjectiveEntry }, context: ExpressionContext.ExpressionContext): (string?, string?)
	for _, entry in ipairs(objectiveList) do
		local isSubState = ((entry :: any).SubState ~= nil)
		
		if isSubState then
			local subStateEntry = entry :: { parsedObjective: ParsedObjective.ParsedObjective, SubState: { [number]: ParsedObjectiveEntry } }
			
			if subStateEntry.parsedObjective:evaluateCondition(context) then
				-- Parent condition met: Recursively check the SubState objectives.
				local textKey, tagStr = self:getActiveObjectiveByFirstValid(subStateEntry.SubState, context)
				if textKey then
					return textKey, tagStr -- Return the lowest active SubState objective
				end
			end
		else
			-- Handle ParsedObjective (Final Leaf Node)
			local parsedObjective = entry :: ParsedObjective.ParsedObjective
			
			if parsedObjective:evaluateCondition(context) then
				-- Found the lowest active objective.
				local textKey = parsedObjective:getLocalizedTextKey()
				local tagStr = parsedObjective:evaluateTag(context)

				-- Check if it has text (to filter out silent deactivation objectives)
				if textKey and textKey ~= "" then
					return textKey, tagStr
				end
			end
		end
	end

	return nil, nil -- No active objective found in this list/substate
end

function ObjectiveManager.getDisplayedObjectives(self: ObjectiveManager, context: ExpressionContext.ExpressionContext): { [string]: {text: string, tag: string} }
	local displayData: { [string]: {text: string, tag: string} } = {}

	for headerName, objectiveList in pairs(self.parsedObjectives) do
		local textKey, tagStr = self:getActiveObjectiveByFirstValid(objectiveList, context)
		
		if textKey and tagStr then
			displayData[headerName] = {
				text = textKey,
				tag = tagStr,
			}
		end
	end

	return displayData
end

return ObjectiveManager