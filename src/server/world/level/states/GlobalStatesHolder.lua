--!strict

local globalStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}
local statesChangedSignal: BindableEvent = Instance.new("BindableEvent")
local registeredStatesInitValues: { [string]: any } = {}

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
		if not registeredStatesInitValues[stateName] then
			registeredStatesInitValues[stateName] = stateValue
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
	return statesChangedSignal.Event
end

function GlobalStatesHolder.resetAllStates(predicate: ((stateName: string) -> boolean)?): ()
	for stateName, stateValue in globalStates do
		if predicate and predicate(stateName) then
			globalStates[stateName] = nil
			continue
		end

		-- TODO: Maybe use the method instead to fire listeners?
		-- TODO: Maybe don't set it to the first value at all
		-- and let the ones who set it dynamically handle it.
		if registeredStatesInitValues[stateName] then
			globalStates[stateName] = registeredStatesInitValues[stateName]
		end
	end
end

return GlobalStatesHolder