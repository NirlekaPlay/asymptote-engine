--!strict

export type StatesHolder = {
	setState: <T>(stateName: string, stateValue: T) -> (),
	getState: (stateName: string) -> any,
	hasState: (stateName: string) -> boolean,
	getStateChangedConnection: (stateName: string) -> RBXScriptSignal<any>,
	getStatesChangedConnection: () -> RBXScriptSignal<string, any>
}

return nil