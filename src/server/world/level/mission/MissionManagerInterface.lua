--!strict

export type MissionManagerInterface = {
	isConcluded: (self: MissionManagerInterface) -> boolean,
	concludeMission: (self: MissionManagerInterface) -> ()
}

return nil