--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local BubbleChatControl = require(script.Parent.BubbleChatControl)

local EPSILON = 0.01
local WORDS_PER_MINUTE = 160
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
local rng = Random.new()

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
	faceControl: FaceControl.FaceControl,
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

function TalkControl.new(character: Model, bubControl: BubbleChatControl, faceControl: FaceControl.FaceControl): TalkControl
	return setmetatable({
		character = character,
		bubbleChatControl = bubControl,
		faceControl = faceControl,
		talkThread = nil :: thread?,
		_diedConnection = nil :: RBXScriptConnection?
	}, TalkControl)
end

function TalkControl.isTalking(self: TalkControl): boolean
	return self.talkThread ~= nil
end

function TalkControl.stopTalking(self: TalkControl): ()
	if self.talkThread then
		task.cancel(self.talkThread)
		self.talkThread = nil
		(self.bubbleChatControl :: BubbleChatControl.BubbleChatControl):clearBubble()
	end
	
	if self.faceControl then
		self.faceControl:resetMouthToExpression()
	end
end

function TalkControl.say(self: TalkControl, text: string, customSpeechDur: number?): ()
	self:createTalkThread({{ text = text, customSpeechDur = nil }})
end

function TalkControl.saySequences(self: TalkControl, textArray: {string}, ...): ()
	self:createTalkThread(self:createDialogueSegmentFromArray(textArray, ...))
end

function TalkControl.saySequencesWithDelay(self: TalkControl, textArray: {string}, delayInSecs: number, ...): ()
	self:createTalkThread(self:createDialogueSegmentFromArray(textArray, ...), delayInSecs)
end

function TalkControl.sayRandomSequences(self: TalkControl, randomDialoguesArray: {{string}}, ...): ()
	local selectedDialogue = TalkControl.randomlyChooseDialogueSequences(randomDialoguesArray)
	if selectedDialogue then
		self:createTalkThread(self:createDialogueSegmentFromArray(selectedDialogue, ...))
	end
end

function TalkControl.randomlyChooseDialogueSequences(randomDialoguesArray: {{string}}): {string}
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

function TalkControl.createTalkThread(self: TalkControl, dialogueSegment: DialogueSegment, delayInSecs: number?): ()
	self:connectOnDiedConnection()
	if self.talkThread then
		task.cancel(self.talkThread)
	end

	local function f()
		for _, segment in pairs(dialogueSegment) do
			local speechDur = segment.customSpeechDur or TalkControl.getStringSpeechDuration(segment.text)
			local finalText = segment.text
			if segment.values and #segment.values >= 1 then
				finalText = (finalText :: any):format(table.unpack(segment.values))
			end

			self.bubbleChatControl:displayBubble(finalText)
			TalkControl.performLipSync(self.faceControl, finalText, speechDur)
		end

		if self.faceControl then
			self.faceControl:resetMouthToExpression()
		end

		self.talkThread = nil
	end

	-- NOTES: This should be on client-side, but I haven't seen any signifficant
	-- performance difference, yet.
	-- But I'm too lazy to implement the agonizing pain that is server-client communication.
	if delayInSecs and delayInSecs > EPSILON then
		self.talkThread = task.delay(delayInSecs, f)
	else
		self.talkThread = task.spawn(f)
	end
end

--

local PHONEME_MAP = {
	-- Vowels
	["a"] = "A", ["e"] = "E", ["i"] = "E", ["o"] = "O", ["u"] = "O",
	-- Consonants
	["m"] = "M", ["b"] = "M", ["p"] = "M", -- Bilabial
	["f"] = "F", ["v"] = "F", -- Labiodental
	["l"] = "L", ["d"] = "L", ["t"] = "L", ["n"] = "L", -- Alveolar
	["s"] = "S", ["z"] = "S", -- Sibilants
	["r"] = "R", ["w"] = "W",
}

local function textToPhonemes(text: string): {string}
	local phonemes = {}
	local lower = text:lower()
	local i = 1
	
	while i <= #lower do
		local char = lower:sub(i, i)
		local twoChar = lower:sub(i, i + 1)
		
		if PHONEME_MAP[twoChar] then
			table.insert(phonemes, PHONEME_MAP[twoChar])
			i += 2
		elseif PHONEME_MAP[char] then
			table.insert(phonemes, PHONEME_MAP[char])
			i += 1
		elseif char:match("%s") then
			table.insert(phonemes, "REST")
			i += 1
		else
			i += 1
		end
	end
	
	return phonemes
end

local function calculateDuration(text: string): number
	local wordCount = 0
	for word in text:gmatch("%S+") do
		wordCount += 1
	end
	return (wordCount / WORDS_PER_MINUTE) * 60
end

function TalkControl.performLipSync(faceControl: FaceControl.FaceControl, text: string)
	local phonemes = textToPhonemes(text)
	if #phonemes == 0 then return end
	
	local duration = calculateDuration(text)
	local stepDuration = duration / #phonemes
	
	for _, phoneme in phonemes do
		if phoneme == "REST" then
			faceControl:resetMouthToExpression()
		else
			faceControl:setMouthPhoneme(phoneme :: any)
		end
		task.wait(stepDuration)
	end
	
	faceControl:resetMouthToExpression()
end

--

function TalkControl.connectOnDiedConnection(self: TalkControl): ()
	if self._diedConnection then
		return
	end

	local humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	self._diedConnection = humanoid.Died:Once(function()
		if not self.talkThread then
			(self.bubbleChatControl :: BubbleChatControl.BubbleChatControl):clearBubble()
			return
		end
		task.cancel(self.talkThread :: thread)
		self.talkThread = nil
		local randomIndex = math.random(1, RANDOM_DEATH_DIALOGUES_SIZE)
		local indexedDialogue = RANDOM_DEATH_DIALOGUES[randomIndex]
		self.bubbleChatControl:displayBubble(indexedDialogue)
	end)
end

--

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