--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Agent = require("../../Agent")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local BubbleChatControl = require("../control/BubbleChatControl")
local Goal = require("./Goal")

local ShockedGoal = {}
ShockedGoal.__index = ShockedGoal

export type ShockedGoal = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	hasBeenShocked: boolean,
	isSpeaking: boolean
}, ShockedGoal)) & Goal.Goal

function ShockedGoal.new(agent: Agent.Agent): ShockedGoal
	return setmetatable({
		agent = agent,
		flags = { "SHOCKED" },
		hasBeenShocked = false,
		isSpeaking = false
	}, ShockedGoal)
end

function ShockedGoal.canUse(self: ShockedGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	local hasSuspect = susMan.excludedSuspect
	if not hasSuspect then
		return false
	end
	local highestStatus = PlayerStatusRegistry.getPlayerStatuses(hasSuspect.suspect):getHighestPriorityStatus()
	local isArmed = highestStatus == "ARMED"

	return isArmed
end

function ShockedGoal.canContinueToUse(self: ShockedGoal): boolean
	return self:canUse() or self.hasBeenShocked
end

function ShockedGoal.isInterruptable(self: ShockedGoal): boolean
	return false
end

function ShockedGoal.getFlags(self: ShockedGoal): {Flag}
	return self.flags
end

local randomDialogues: {(BubbleChatControl.BubbleChatControl, ShockedGoal) -> ()} = {
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Wait wait wait!")
		task.wait(1)
		bubControl:displayBubble("Lets talk about this!")
		task.wait(1)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Woah woah woah!")
		task.wait(.6)
		bubControl:displayBubble("Holy shit you have a gun?!")
		task.wait(1)
		bubControl:displayBubble("Do you even have a license for that?!")
		task.wait(1)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Wait wait wait!")
		task.wait(.7)
		bubControl:displayBubble("Don't shoot!!!")
		task.wait(1)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Awh fuck!")
		task.wait(.7)
		bubControl:displayBubble("Okay okay!")
		task.wait(1)
		bubControl:displayBubble("You don't need to leave!")
		task.wait(1)
		self.isSpeaking = false
	end,
}

local randomDeathDialogues = {
	"Agh-",
	"Egh-",
	"Ggh-",
	"NO--",
	"NO WAIT-",
	"No-",
	"WAIT-"
}

function ShockedGoal.start(self: ShockedGoal): ()
	ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp:Play()
	self.hasBeenShocked = true
	local faceControl = self.agent:getFaceControl()
	faceControl:setFace("Shocked")
	local bubControl = self.agent:getBubbleChatControl()
	local randomIndexDialogue = math.random(1, #randomDialogues)

	self.isSpeaking = true
	local speakThread = task.spawn(function()
		task.wait(0.3)
		randomDialogues[randomIndexDialogue](bubControl, self)
	end);

	(self.agent.character.Humanoid :: Humanoid).Died:Once(function()
		if self.isSpeaking then
			task.cancel(speakThread)
			bubControl:displayBubble(randomDeathDialogues[math.random(1, #randomDeathDialogues)])
			self.isSpeaking = false
		end
	end)
end

function ShockedGoal.stop(self: ShockedGoal): ()
	return
end

function ShockedGoal.update(self: ShockedGoal, delta: number?): ()
	return
end

function ShockedGoal.requiresUpdating(self: ShockedGoal): boolean
	return false
end

return ShockedGoal