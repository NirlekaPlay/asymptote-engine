--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GunControl = require(ServerScriptService.server.ai.control.GunControl)
local Agent = require("../../Agent")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local BubbleChatControl = require("../control/BubbleChatControl")
local Goal = require("./Goal")

local ShockedGoal = {}
ShockedGoal.__index = ShockedGoal

export type ShockedGoal = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	hasBeenShocked: boolean,
	shockedBy: Player?,
	initialShockerDistance: number?,
	isSpeaking: boolean,
}, ShockedGoal)) & Goal.Goal

function ShockedGoal.new(agent: Agent.Agent): ShockedGoal
	return setmetatable({
		agent = agent,
		flags = { "SHOCKED", "MOVING" },
		hasBeenShocked = false,
		shockedBy = nil,
		isSpeaking = false
	}, ShockedGoal)
end

function ShockedGoal.canUse(self: ShockedGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	local hasSuspect = susMan:getFocusingTarget()
	if not hasSuspect then
		return false
	end
	if not susMan.detectionLocks[hasSuspect] then
		return false
	end
	local highestStatus = PlayerStatusRegistry.getPlayerStatuses(hasSuspect):getHighestPriorityStatus()
	local isArmed = highestStatus == "ARMED"

	if isArmed then
		self.shockedBy = hasSuspect
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
		task.wait(1.32)
		bubControl:displayBubble("Lets talk about this!")
		task.wait(2)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Woah woah woah!")
		task.wait(1.47)
		bubControl:displayBubble("Holy shit you have a gun?!")
		task.wait(2.28)
		bubControl:displayBubble("Do you even have a license for that?!")
		task.wait(2.30)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Wait wait wait!")
		task.wait(1.47)
		bubControl:displayBubble("Don't shoot!!!")
		task.wait(1.56)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Awh fuck!")
		task.wait(1.61)
		bubControl:displayBubble("Okay okay!")
		task.wait(1.40)
		bubControl:displayBubble("You don't need to leave!")
		task.wait(2)
		self.isSpeaking = false
	end,
}

local randomShooterDialogues: {(BubbleChatControl.BubbleChatControl, ShockedGoal) -> ()} = {
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Oh shit! Hes got a gun!")
		task.wait(1.66)
		bubControl:displayBubble("Open fire!")
		task.wait(0.98)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("Control! Ive got an armed trespasser here!!!!")
		task.wait(2.83)
		self.isSpeaking = false
	end,
	function(bubControl: BubbleChatControl.BubbleChatControl, self: ShockedGoal)
		bubControl:displayBubble("We got a shooter!")
		task.wait(1.49)
		bubControl:displayBubble("Envvy! Save us!!")
		task.wait(1.47)
		self.isSpeaking = false
	end
}

local randomDeathDialogues = {
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

function ShockedGoal.start(self: ShockedGoal): ()
	ReplicatedStorage.shared.assets.sounds.detection_undertale_alert_temp:Play()
	self.hasBeenShocked = true
	local faceControl = self.agent:getFaceControl()
	faceControl:setFace("Shocked")
	local bubControl = self.agent:getBubbleChatControl()
	self.isSpeaking = true
	local speakThread

	local charPos = self.shockedBy.Character.PrimaryPart.Position
	local selfPos = self.agent:getPrimaryPart().Position
	local distance = ( charPos - selfPos ).Magnitude
	self.initialShockerDistance = distance

	self.hasBeenAtGunpoint = true

	if distance < 15 and self.agent:canBeIntimidated() then
		local randomIndexDialogue = math.random(1, #randomDialogues)
		speakThread = task.spawn(function()
			task.wait(0.3)
			randomDialogues[randomIndexDialogue](bubControl, self)
		end);
	elseif (not self.agent:canBeIntimidated()) or distance > 20 then
		local randomIndexDialogue = math.random(1, #randomShooterDialogues)
		speakThread = task.spawn(function()
			task.wait(0.3)
			randomShooterDialogues[randomIndexDialogue](bubControl, self)
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
	local shockerChar = self.shockedBy.Character
	if not shockerChar then return end

	self.agent:getBodyRotationControl():setRotateTowards(shockerChar.PrimaryPart.Position)
	self.agent:getLookControl():setLookAtPos(shockerChar.PrimaryPart.Position)

	local shockerHumanoid = shockerChar:FindFirstChildOfClass("Humanoid")

	if shockerHumanoid.Health <= 0 then
		return
	end

	if self.agent:canBeIntimidated() and self.initialShockerDistance < 15 then
		self.agent:getGunControl():unequipGun()
		return
	end

	local charPos = self.shockedBy.Character.PrimaryPart.Position

	local config: GunControl.GunConfg = {}
	config.fireDelay = 0.01
	config.chamberedBullet = 0
	config.roundsInMagazine = 0
	config.magazineRoundsCapacity = 30
	self.agent:getGunControl():equipGun(config)
	self.agent:getGunControl():shoot(charPos)
	if self.agent:getGunControl():isEmpty() then
		self.agent:getGunControl():reload()
	end
end

function ShockedGoal.requiresUpdating(self: ShockedGoal): boolean
	return true
end

return ShockedGoal