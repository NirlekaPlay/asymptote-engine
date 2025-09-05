export type StatusProperties = {
    name: string,
    priority: number,
    requiresVisibility: boolean,
    detectionSpeedModifier: number?,
}
export type Status = {} & StatusProperties

return {}