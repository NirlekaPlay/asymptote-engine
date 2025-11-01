--!strict

local BubbleChatControl = require(script.Parent.BubbleChatControl)

local WORDS_PER_MINUTE = 140
-- TODO: This was taken from ShockedGoal, where this line will be triggered
-- if the agent was begging for mercy.
-- Maybe we should call an external method from the Agent to return appropriate
-- random death dialogues.
local RANDOM_DEATH_DIALOGUES = {
	"Agh-",
	"Egh-",
	"Ggh-",
	"NO--",
	"NO WAIT-",
	"No-",
	"WAIT-",
	"AGH--",
	"SHI-"
}
local RANDOM_DEATH_DIALOGUES_SIZE = #RANDOM_DEATH_DIALOGUES
local rng = Random.new(tick())

--[=[
	@class TalkControl

	Responsible for both the lip-sync and the bubble chat for Agents
	when talking.
]=]
local TalkControl = {}
TalkControl.__index = TalkControl

export type TalkControl = typeof(setmetatable({} :: {
	character: Model,
	bubbleChatControl: BubbleChatControl, -- TODO: This is dumb.
	talkThread: thread?,
	_diedConnection: RBXScriptConnection?
}, TalkControl))

type DialogueSegment = {
	{
		text: string,
		customSpeechDur: number?,
		values: { any }?
	}
}

type BubbleChatControl = BubbleChatControl.BubbleChatControl

function TalkControl.new(character: Model, bubControl: BubbleChatControl): TalkControl
	return setmetatable({
		character = character,
		bubbleChatControl = bubControl,
		talkThread = nil :: thread?,
		_diedConnection = nil :: RBXScriptConnection?
	}, TalkControl)
end

function TalkControl.isTalking(self: TalkControl): boolean
	return self.talkThread ~= nil
end

function TalkControl.say(self: TalkControl, text: string, customSpeechDur: number?): ()
	self:createTalkThread({{ text = text, customSpeechDur = nil }})
end

function TalkControl.saySequences(self: TalkControl, textArray: {string}): ()
	self:createTalkThread(self:createDialogueSegmentFromArray(textArray))
end

function TalkControl.sayRandomSequences(self: TalkControl, randomDialoguesArray: {{string}}, ...): ()
	local selectedDialogue = TalkControl.randomlyChosoeDialogueSequences(randomDialoguesArray)
	if selectedDialogue then
		self:createTalkThread(self:createDialogueSegmentFromArray(selectedDialogue, ...))
	end
end

function TalkControl.randomlyChosoeDialogueSequences(randomDialoguesArray: {{string}}): {string}
	return randomDialoguesArray[rng:NextInteger(1, #randomDialoguesArray)]
end

function TalkControl.saySegment(self: TalkControl, dialogueSegment: DialogueSegment): ()
	self:createTalkThread(dialogueSegment)
end

function TalkControl.createDialogueSegmentFromArray(self: TalkControl, textArray: {string}, ...): DialogueSegment
	local dialogueSegment: DialogueSegment = {}

	for i, text in ipairs(textArray) do
		-- TODO: Maybe add some optimizations here, like ignore empty strings
		local valuesRef = table.pack(...)
		dialogueSegment[i] = { text = text, values = valuesRef }
	end

	return dialogueSegment
end

function TalkControl.createTalkThread(self: TalkControl, dialogueSegment: DialogueSegment): ()
	self:connectOnDiedConnection()
	if self.talkThread then
		task.cancel(self.talkThread)
	end

	-- NOTES: This should be on client-side, but I haven't seen any signifficant
	-- performance difference, yet.
	-- But I'm too lazy to implement the agonizing pain that is server-client communication.
	self.talkThread = task.spawn(function()
		for _, segment in pairs(dialogueSegment) do
			local speechDur = segment.customSpeechDur or
				TalkControl.getStringSpeechDuration(segment.text)

			local finalText = segment.text
			if segment.values and #segment.values >= 1 then
				finalText = (finalText :: any):format(table.unpack(segment.values))
			end
			self.bubbleChatControl:displayBubble(finalText)
			task.wait(speechDur)
		end

		self.talkThread = nil
	end)
end

function TalkControl.connectOnDiedConnection(self: TalkControl): ()
	if self._diedConnection then
		return
	end

	local humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	self._diedConnection = humanoid.Died:Once(function()
		if not self.talkThread then
			return
		end
		task.cancel(self.talkThread :: thread)
		self.talkThread = nil
		local randomIndex = math.random(1, RANDOM_DEATH_DIALOGUES_SIZE)
		local indexedDialogue = RANDOM_DEATH_DIALOGUES[randomIndex]
		self.bubbleChatControl:displayBubble(indexedDialogue)
	end)
end

function TalkControl.getDialoguesTotalSpeechDuration(dialogues: {string}): number
	local totalDur = 0
	for _, segment in pairs(dialogues) do
		local speechDur = TalkControl.getStringSpeechDuration(segment)
		totalDur += speechDur
	end
	return totalDur
end

function TalkControl.getStringSpeechDuration(str: string): number
	local stringWordCount = TalkControl.getStringWordCount(str)
	if stringWordCount == 0 then
		return 0
	end

	local averageSecondsPerWord = 60 / WORDS_PER_MINUTE
	local totalDuration = 0

	for i = 1, stringWordCount do
		local variation = math.random(90, 110) / 100 -- 0.90 to 1.10
		totalDuration += averageSecondsPerWord * variation
	end

	return totalDuration
end

function TalkControl.getStringWordCount(str: string): number
	local count = 0
	for word in string.gmatch(str, "%S+") do
		count += 1
	end
	return count
end

return TalkControl