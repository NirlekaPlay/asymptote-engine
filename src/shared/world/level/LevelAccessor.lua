--!strict

export type LevelAccessor = {
	clearScene: (self: LevelAccessor) -> (),
	getMapList: (self: LevelAccessor) -> {string},
	loadScene: (self: LevelAccessor, sceneName: string) -> (),
	restartScene: (self: LevelAccessor) -> (),
	isSceneRestarting: (self: LevelAccessor) -> ()
}

return nil