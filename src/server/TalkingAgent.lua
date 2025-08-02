--!strict

export type TalkingAgent = {
	getTrespasserEncounterDialogue: (self: TalkingAgent, player: Player, warns: number) -> string,
	getRandomInterruptedTalkingOnDeathDialogue: (self: TalkingAgent) -> string,
	getOnSeenDangerousItemDialogue: (self: TalkingAgent) -> string,
	getOnSeenArmedPlayerDialogue: (self: TalkingAgent) -> string,
	getOnIntimidatedDialogue: (self: TalkingAgent) -> string
}

return nil