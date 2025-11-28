--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ParsedObjective = require(ServerScriptService.server.world.level.objectives.ParsedObjective)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

--[=[
	@class ObjectiveManager
]=]
local ObjectiveManager = {}
ObjectiveManager.__index = ObjectiveManager

export type ObjectiveManager = typeof(setmetatable({} :: {
	-- Key: Header name (e.g., "Mission", "Stealth")
	-- Value: Table of ParsedObjectiveEntry structures
	parsedObjectives: { [string]: { [number]: ParsedObjectiveEntry } }
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
	Active: string,
	SubState: { [number]: ParsedObjectiveEntry },
}

function ObjectiveManager.new(): ObjectiveManager
	return setmetatable({
		parsedObjectives = {},
	}, ObjectiveManager)
end

function ObjectiveManager.parseObjectiveEntry(rawEntry: RawObjectiveEntry): ParsedObjectiveEntry
	if rawEntry.SubState then
		local subStateTable: { [number]: ParsedObjectiveEntry } = {}
		for i, subEntry in ipairs(rawEntry.SubState) do
			subStateTable[i] = ObjectiveManager.parseObjectiveEntry(subEntry)
		end
		return {
			Active = rawEntry.Active,
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

function ObjectiveManager.fromMissionSetupTable(self: ObjectiveManager, missionTable: RawMissionSetupTable)
	for headerName, objectiveList in pairs(missionTable) do
		-- Skip the Timer table or other non-objective tables if present
		if typeof(objectiveList) == "table" and headerName ~= "Timer" then
			print(headerName, objectiveList)
			local parsedList: { [number]: ParsedObjectiveEntry } = {}
			for i, rawEntry in ipairs(objectiveList) do
				parsedList[i] = ObjectiveManager.parseObjectiveEntry(rawEntry)
			end
			self.parsedObjectives[headerName] = parsedList
		end
	end
end

function ObjectiveManager.setActiveObjectiveToFirstValid(self: ObjectiveManager, objectiveList: { [number]: ParsedObjectiveEntry }, context: ExpressionContext.ExpressionContext): (string?, string?)
	for _, entry in ipairs(objectiveList) do
		local isSubState = (entry.SubState ~= nil)
		
		if isSubState then
			local subStateEntry = entry :: { Active: string, SubState: { [number]: ParsedObjectiveEntry } }
			
			-- Evaluate the parent condition string (Active) for the SubState container
			local conditionMet = ExpressionParser.evaluate(
				ExpressionParser.fromString(subStateEntry.Active):parse(),
				context
			)
			
			if conditionMet then
				-- Parent condition met: Recursively check the SubState objectives.
				local textKey, tagStr = self:setActiveObjectiveToFirstValid(subStateEntry.SubState, context)
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
		local textKey, tagStr = self:setActiveObjectiveToFirstValid(objectiveList, context)
		
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