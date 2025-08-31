--!strict

export type BrainDump = {
	uuid: string,
	name: string,
	character: Model,
	health: number,
	maxHealth: number,
	memories: { string },
	behaviors: { string },
	activites: { string },
	detectedStatuses: { string },
	suspicionLevels: { string }
}

return nil