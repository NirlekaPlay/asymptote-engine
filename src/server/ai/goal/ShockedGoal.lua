--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)
local Agent = require("../../Agent")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local BubbleChatControl = require("../control/BubbleChatControl")
local Goal = require("./Goal")

local ShockedGoal = {}
ShockedGoal.__index = ShockedGoal

export type ShockedGoal = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	hasBeenShocked: boolean,
	shocker: PlayerStatus.PlayerStatusType?,
	isSpeaking: boolean,
	hasBeenAtGunpoint: boolean
}, ShockedGoal)) & Goal.Goal

function ShockedGoal.new(agent: Agent.Agent): ShockedGoal
	return setmetatable({
		agent = agent,
		flags = { "SHOCKED" },
		hasBeenShocked = false,
		shocker = nil,
		isSpeaking = false,
		hasBeenAtGunpoint = false
	}, ShockedGoal)
end

function ShockedGoal.canUse(self: ShockedGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	local hasSuspect = susMan.excludedSuspect
	if not hasSuspect then
		return false
	end
	local highestStatus = PlayerStatusRegistry.getPlayerStatuses(hasSuspect.suspect):getHighestPriorityStatus()
	local isArmed = highestStatus == "ARMED" or highestStatus == "DANGEROUS_ITEM"
	if isArmed then
		self.shocker = highestStatus
	end
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

local randomBombDialogues: {(BubbleChatControl.BubbleChatControl, ShockedGoal) -> ()} = {
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Oh SHIT HES GOT A BOMB!")
		task.wait(1)
		bubControl:displayBubble("AH FUCK!")
		task.wait(1)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("OH FUCK OH FUCK OH FUCK!")
		task.wait(1)
		bubControl:displayBubble("TO VALHALLA!")
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Wait wait wait!")
		task.wait(.7)
		bubControl:displayBubble("Is that a real bomb?!")
		task.wait(1)
		bubControl:displayBubble("Dont detonate it on me!!!")
		task.wait(1)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Oh fuck!")
		task.wait(1)
		bubControl:displayBubble("ITS A BOMB!")
		task.wait(1)
		bubControl:displayBubble("CONTROL, I NEED BACKUP!")
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

local inMag = 1
local maxRoundsInMag = 10
local shootSpeed = 0.1

local function giveOrGetAgentGun(self: ShockedGoal): Tool
	local fbb = self.agent.character:FindFirstChild("FBB")
	if not fbb then
		local newFbb = game.ServerStorage.FBB:Clone()
		newFbb.Parent = self.agent.character
		newFbb.settings.inmag.Value = inMag
		newFbb.settings.maxmagcapacity.Value = maxRoundsInMag
		newFbb.settings.speed.Value = shootSpeed
		fbb = newFbb
	end

	fbb.settings.inmag.Value = inMag
	fbb.settings.maxmagcapacity.Value = maxRoundsInMag
	fbb.settings.speed.Value = shootSpeed

	return fbb
end

local function fireAgentGun(self: ShockedGoal): ()
	local suspect = self.agent:getSuspicionManager().excludedSuspect
	if not suspect then
		return
	end
	suspect = suspect.suspect
	local fbb = giveOrGetAgentGun(self)

	local remote = fbb.fire :: BindableEvent
	remote:Fire("2", suspect.Character.PrimaryPart.Position)
end

local function unequipAgentGun(self: ShockedGoal): ()
	local fbb = giveOrGetAgentGun(self)

	local remote = fbb.unequip :: BindableEvent
	remote:Fire()
	task.delay(1, function()
		fbb:Destroy()
	end)
end

function ShockedGoal.start(self: ShockedGoal): ()
	ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp:Play()
	self.hasBeenShocked = true
	local faceControl = self.agent:getFaceControl()
	faceControl:setFace("Shocked")
	local bubControl = self.agent:getBubbleChatControl()
	self.isSpeaking = true
	local speakThread

	if self.shocker == "ARMED" then
		self.hasBeenAtGunpoint = true
		local randomIndexDialogue = math.random(1, #randomDialogues)

		speakThread = task.spawn(function()
			task.wait(0.3)
			randomDialogues[randomIndexDialogue](bubControl, self)
		end);
	else
		local randomIndexDialogue = math.random(1, #randomBombDialogues)

		speakThread = task.spawn(function()
			task.wait(0.3)
			randomBombDialogues[randomIndexDialogue](bubControl, self)
		end);
	end

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
	if not self.isSpeaking and self.shocker == "DANGEROUS_ITEM" then
		fireAgentGun(self)
	elseif not self.isSpeaking and self.shocker == "ARMED" and not self.hasBeenAtGunpoint then
		self:start()
	end
end

function ShockedGoal.requiresUpdating(self: ShockedGoal): boolean
	return true
end

return ShockedGoal