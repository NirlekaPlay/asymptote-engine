--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local DialogueSequences = require(ReplicatedStorage.shared.dialogue.DialogueSequences)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local DialogueUIHandler = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.dialogue.DialogueUIHandler)
local UString = require(ReplicatedStorage.shared.util.string.UString)

local RICH_TEXT_TRANSPARENCY_TAG = '<font transparency="100">%s</font>'
local WORD_PER_SEC = 300 / 60
local AVG_CHARS_PER_WORD = 12
local WAIT_TIME_AFTER_TYPE_ANIM = 3
local INITIAL_DELAY = 0.3
local DEFAULT_WAIT_TIME_BETWEEN_LINES = 1
local NIL_SPEAKER_ID_FALLBACK = "UNREGISTERED_SPEAKER_ID"

local PUNCTUATION_WAITS = {
	[","] = 0.08,
	["."] = 0.20,
	["?"] = 0.25,
	["!"] = 0.25,
	[":"] = 0.15,
	[";"] = 0.15,
	["-"] = 0.05,
}

local currentTypeThread: thread? = nil
local speakerNamesByIds: { [string]: MutableTextComponent.MutableTextComponent } = {}

--[=[
	@class DialogueController
]=]
local DialogueController = {}

type DialogueSequences = DialogueSequences.DialogueSequences

local function typeOut(dialogue: string)
	local msgCount = #dialogue
	local totalWords = msgCount / AVG_CHARS_PER_WORD
	local totalDuration = totalWords / WORD_PER_SEC
	local charCount = msgCount
	local delayPerChar = totalDuration / charCount
	local defaultDelay = math.max(0.01, delayPerChar)
	
	local explodedText = UString.explodeString(dialogue)
	local explodedTextCount = #explodedText
	local finalString = ""
	local revealedCount = 0
	
	local i = 1
	while i <= explodedTextCount do
		local char = explodedText[i]
		local currentWait: number = defaultDelay
		
		local punctuationWait = PUNCTUATION_WAITS[char]
		if punctuationWait then
			currentWait = punctuationWait
			
			-- Consume all consecutive related punctuation marks
			-- This handles "!?!?!??!?" as one event.
			local j = i + 1
			while j <= explodedTextCount do
				local nextChar = explodedText[j]
				if PUNCTUATION_WAITS[nextChar] then
					-- Continue as long as the next character is also punctuation
					j = j + 1
				else
					break
				end
			end
			
			-- Update the revealed text to include all consumed characters
			-- i is the start of the punctuation block, j-1 is the end.
			revealedCount = j - 1
			i = j -- Set 'i' to the character AFTER the block for the next loop iteration
		else
			revealedCount = i
			i += 1
		end

		local visiblePart = table.concat(explodedText, "", 1, revealedCount)
		local transparentPart = ""
		
		if revealedCount < explodedTextCount then
			local hiddenCharacters = table.concat(explodedText, "", revealedCount + 1, #explodedText)
			transparentPart = (string.format :: any)(RICH_TEXT_TRANSPARENCY_TAG, hiddenCharacters) 
		end
		
		finalString = visiblePart .. transparentPart

		DialogueUIHandler.setDialogueText(finalString)
		
		task.wait(currentWait)
	end
end

function DialogueController.registerSpeakerId(speakerId: string, component: MutableTextComponent.MutableTextComponent): ()
	speakerNamesByIds[speakerId] = component
end

function DialogueController.forceClose(): ()
	if currentTypeThread then
		task.cancel(currentTypeThread)
	end

	DialogueUIHandler.transitionDialogue(false)
end

function DialogueController.typeOutDialogue(speaker: MutableTextComponent.MutableTextComponent, dialouge: string): ()
	if currentTypeThread then
		task.cancel(currentTypeThread)
	end

	DialogueUIHandler.setSpeakertext(speaker:buildRichTextMarkupString())
	DialogueUIHandler.setDialogueText("")
	DialogueUIHandler.transitionDialogue(true)

	currentTypeThread = task.spawn(function()
		task.wait(INITIAL_DELAY)
		typeOut(dialouge)
		task.wait(WAIT_TIME_AFTER_TYPE_ANIM)
		DialogueUIHandler.transitionDialogue(false)
	end)
end

function DialogueController.typeOutDialogueSequences(sequences: DialogueSequences)
	if currentTypeThread then
		task.cancel(currentTypeThread)
	end

	DialogueUIHandler.setDialogueText("")
	DialogueUIHandler.transitionDialogue(true)

	local firstTime = true
	currentTypeThread = task.spawn(function()
		for _, speakerBlock in sequences do
			local fetch = speakerNamesByIds[speakerBlock.SpeakerId]
			local name: MutableTextComponent.MutableTextComponent?
			if fetch then
				name = fetch
			end
			local finalName = name and name:buildRichTextMarkupString() or NIL_SPEAKER_ID_FALLBACK
			local nameSet = false

			for i, dialogueEntry in speakerBlock.Dialogues do
				if firstTime then
					firstTime = false
					nameSet = true
					DialogueUIHandler.setSpeakertext(finalName)
					task.wait(INITIAL_DELAY)
				else
					local delayTime = dialogueEntry.InitialDelay or DEFAULT_WAIT_TIME_BETWEEN_LINES
					task.wait(delayTime)
				end

				DialogueUIHandler.setDialogueText("")
				if not nameSet then
					nameSet = true
					DialogueUIHandler.setSpeakertext(finalName)
				end
				typeOut(dialogueEntry.Text)
			end
		end
		
		task.wait(WAIT_TIME_AFTER_TYPE_ANIM)
		DialogueUIHandler.transitionDialogue(false)
	end)
end

return DialogueController