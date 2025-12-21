--!strict

local globalStates: { [string]: any } = {}
local stateSignals: { [string]: BindableEvent } = {}
local allStateChangedSignal: BindableEvent = Instance.new("BindableEvent")

local ReplicatedGlobalStates = {}

function ReplicatedGlobalStates.setState<T>(stateName: string, stateValue: T): ()
	local prevValue = globalStates[stateName]

	if prevValue ~= stateValue :: any then
		allStateChangedSignal:Fire(stateName, stateValue)
		globalStates[stateName] = stateValue
		if stateSignals[stateName] then
			stateSignals[stateName]:Fire(stateValue)
		end
	end
end

function ReplicatedGlobalStates.getState(stateName: string): any
	return globalStates[stateName]
end

function ReplicatedGlobalStates.getAllStates(): { [string]: any }
	return globalStates
end

function ReplicatedGlobalStates.hasState(stateName: string): boolean
	return globalStates[stateName] ~= nil
end

function ReplicatedGlobalStates.getStateChangedConnection(stateName: string): RBXScriptSignal<any>
	if not stateSignals[stateName] then
		if ReplicatedGlobalStates.hasState(stateName) then
			stateSignals[stateName] = Instance.new("BindableEvent")
		else
			error(`Attempt to subscribe to a nil state '{stateName}'`)
		end
	end

	return stateSignals[stateName].Event
end

function ReplicatedGlobalStates.getStatesChangedConnection(): RBXScriptSignal<string, any>
	return allStateChangedSignal.Event
end

return ReplicatedGlobalStates