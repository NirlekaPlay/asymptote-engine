--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueConcept = require(ReplicatedStorage.shared.dialogue.DialogueConcept)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

export type ClientBoundDialogueConceptsPayload = {
	speakers: {
		[string]: MutableTextComponent.SerializedComponentResult
	},
	concepts: {
		[string]: { DialogueConcept.DialogueConcept }
	}
}

return nil