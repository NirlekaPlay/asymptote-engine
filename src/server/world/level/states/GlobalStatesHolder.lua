--!strict

local globalStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}

local GlobalStatesHolder = {}

function GlobalStatesHolder.setState<T>(stateName: string, stateValue: T): ()
	local prevValue = globalStates[stateName]

	if prevValue ~= stateValue :: any then
		globalStates[stateName] = stateValue
			if stateSignals[stateName] then
			stateSignals[stateName]:Fire(stateValue)
		end
	end
end

function GlobalStatesHolder.getState(stateName: string): any
	return globalStates[stateName]
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

return GlobalStatesHolder