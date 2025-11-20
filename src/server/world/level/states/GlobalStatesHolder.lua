--!strict

local globalStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}
local statesChangedSignal: BindableEvent = Instance.new("BindableEvent")

local GlobalStatesHolder = {}

function GlobalStatesHolder.setState<T>(stateName: string, stateValue: T): ()
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
	return statesChangedSignal.Event
end

return GlobalStatesHolder