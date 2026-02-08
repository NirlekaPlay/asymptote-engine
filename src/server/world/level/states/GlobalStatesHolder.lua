--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.shared.thirdparty.Signal)

local DEBUG_STATE_CHANGES = false

local globalStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}
local statesChangedSignal: Signal.Signal<string, any> = Signal.new()

local GlobalStatesHolder = {}

function GlobalStatesHolder.setState<T>(stateName: string, stateValue: T): ()
	-- Returns true if the string is empty or full of only whitespaces
	if string.match(stateName, "%S") == nil then
		error(`Attempt to set a state with a name of '{stateName}': The state name is an empty string or full of whitespaces!`)
		return
	end

	local prevValue = globalStates[stateName]

	if prevValue ~= stateValue :: any then
		globalStates[stateName] = stateValue
		statesChangedSignal:Fire(stateName, stateValue)
		if stateSignals[stateName] then
			stateSignals[stateName]:Fire(stateValue)
		end
	end
end

function GlobalStatesHolder.getState(stateName: string): any
	return globalStates[stateName]
end

function GlobalStatesHolder.getAllStatesReference(): typeof(globalStates)
	return globalStates
end

function GlobalStatesHolder.hasState(stateName: string): boolean
	return globalStates[stateName] ~= nil
end

function GlobalStatesHolder.getStateChangedConnection(stateName: string): RBXScriptSignal<any>
	if not stateSignals[stateName] then
		if GlobalStatesHolder.hasState(stateName) then
			stateSignals[stateName] = Instance.new("BindableEvent")
		else
			error(`Attempt to subscribe to a nil state '{stateName}'`)
		end
	end

	return stateSignals[stateName].Event
end

function GlobalStatesHolder.getStatesChangedConnection(): RBXScriptSignal<string, any>
	return statesChangedSignal
end

function GlobalStatesHolder.resetAllStates(predicate: ((stateName: string) -> boolean)?): ()
	for stateName, stateValue in globalStates do
		if predicate and predicate(stateName) then
			if DEBUG_STATE_CHANGES then
				print(`VARIABLE '{stateName}' RESET TO NIL.`)
			end
			globalStates[stateName] = nil
			continue
		end

		if DEBUG_STATE_CHANGES then
			print(`VARIABLE '{stateName}' LEFT AS IS.`)
		end
	end
end

function GlobalStatesHolder.nullifyAllStatesAndEvents(): ()
	-- I don't want any lingering references in this shit
	table.clear(globalStates)

	for stateName, stateEvent in stateSignals do
		if stateEvent then
			stateEvent:Destroy()
		end
	end

	table.clear(stateSignals)

	statesChangedSignal:Destroy()
	statesChangedSignal = nil :: any

	statesChangedSignal = Signal.new()
end

return GlobalStatesHolder