--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueSequences = require(ReplicatedStorage.shared.dialogue.DialogueSequences)

export type DialogueConcept = {
	id: string,
	condition: string,
	dialogueSequence: DialogueSequences.DialogueSequences,
	priority: number
}

return nil