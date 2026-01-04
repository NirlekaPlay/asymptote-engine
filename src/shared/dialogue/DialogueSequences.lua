--!strict

export type DialogueSequences = {
	{
		SpeakerId: string,
		Dialogues: {
			{
				InitialDelay: number?,
				Text: string
			}
		}
	}
}

return nil