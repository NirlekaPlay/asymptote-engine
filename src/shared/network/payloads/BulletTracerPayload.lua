--!strict

export type BulletTracer = {
	origin: Vector3,
	direction: Vector3,
	speed: number,
	size: Vector3,
	penetration: number,
	humanoidRootPartVelocity: number,
	muzzleCframe: CFrame,
	seed: number
}

return nil