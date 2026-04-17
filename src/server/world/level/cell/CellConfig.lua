--!strict

export type BluffConfig = {
	socialEngineeringLevel: number,
	excuse: string,
	responseSpeaker: string,
	response: string,
	variable: string,
}

export type CellConfig = {
	trespass: boolean,
	allow: {[string]: true}?,
	minorTrespass: {[string]: true}?,
	enforce: {[string]: true}?,
	enforceMinor: {[string]: true}?,
	minorTrespassBluff: BluffConfig?,
}

export type ParsedCellEntry = 
	{ kind: "config", config: CellConfig } |
	{ kind: "expression", expression: string }

export type ParsedCellConfigs = { [string]: ParsedCellEntry }

return nil