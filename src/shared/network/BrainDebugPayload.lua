--!strict

export type BrainDump = {
	uuid: string,
	name: string,
	character: Model,
	health: string,
	maxHealth: string,
	memories: { string },
	behaviors: { [string]: true },
	activites: { [string]: true }
}

return nil