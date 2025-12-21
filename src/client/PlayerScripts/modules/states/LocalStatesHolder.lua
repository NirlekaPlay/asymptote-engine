--!strict

local localStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}
local allStateChangedSignal: BindableEvent = Instance.new("BindableEvent")

local LocalStatesHolder = {}

function LocalStatesHolder.setState<T>(stateName: string, stateValue: T): ()
	local prevValue = localStates[stateName]

	if prevValue ~= stateValue :: any then
		allStateChangedSignal:Fire(stateName, stateValue)
		localStates[stateName] = stateValue
		if stateSignals[stateName] then
			stateSignals[stateName]:Fire(stateValue)
		end
	end
end

function LocalStatesHolder.getState(stateName: string): any
	return localStates[stateName]
end

function LocalStatesHolder.getAllStates(): { [string]: any }
	return localStates
end

function LocalStatesHolder.hasState(stateName: string): boolean
	return localStates[stateName] ~= nil
end

function LocalStatesHolder.getStateChangedConnection(stateName: string): RBXScriptSignal<any>
	if not stateSignals[stateName] then
		if LocalStatesHolder.hasState(stateName) then
			stateSignals[stateName] = Instance.new("BindableEvent")
		else
			error(`Attempt to subscribe to a nil state '{stateName}'`)
		end
	end

	return stateSignals[stateName].Event
end

function LocalStatesHolder.getStatesChangedConnection(): RBXScriptSignal<string, any>
	return allStateChangedSignal.Event
end

return LocalStatesHolder